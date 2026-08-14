class InstructorController < ApplicationController
  allow_only :staff

  def show
    @section = Section.for_staff(Current.user)

    # Staff with nothing to teach, and no section in the database to fall back
    # on: the screen says so rather than averaging over an empty roster.
    @report = InstructorReport.new(@section) if @section
    @integrity_settings = LessonIntegritySetting.rows_for(@section.course) if @section
    # The course this teacher teaches, which is theirs to edit and to ask about
    # (ADR-0054). An administrator holding the staff role teaches nothing, and
    # sees no course panel here.
    @course = teachable_course

    # The bar, and which of its panels is open. Nothing to teach means no bar:
    # the empty state below is the whole screen.
    return unless @section

    @tabs = TeachingConsole.tabs_for(course: @course)
    @tab = TeachingConsole.tab_for(params[:tab], course: @course)
    @badges = TeachingConsole.badges(report: @report, integrity_settings: @integrity_settings)
    @outline = SyllabusBuilder.new(@course).outline if @tab == :syllabus
    # One query for the whole tab rather than one per lesson: the panel draws
    # three stances for every topic in the syllabus.
    if @tab == :integrity
      @ai_policies = LessonAiPolicy.rows_for_all(course: @section.course,
                                                 topic_keys: @integrity_settings.map(&:topic_key))
    end
  end

  def update_integrity_setting
    section = Section.for_staff(Current.user)
    topic_key = params[:topic_key].to_s

    unless section && Syllabus.topic_keys(section.course.code).include?(topic_key)
      redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_forbidden")
      return
    end

    enabled = LessonIntegritySetting.parse_boolean(params[:enabled])
    unless !enabled.nil?
      redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_invalid")
      return
    end

    previous = LessonIntegritySetting.find_by(course: section.course, topic_key:)&.enabled != false
    LessonIntegritySetting.transaction do
      LessonIntegritySetting.update!(course: section.course, topic_key:, enabled:,
                                     expected_lock_version: params[:lock_version])
      AuditEvent.record("lesson_integrity_setting_changed", course: section.course.code, topic: topic_key,
                        from_state: previous ? "on" : "off", to_state: enabled ? "on" : "off")
    end

    redirect_to instructor_path(tab: :integrity),
                notice: t("flash.lesson_integrity_setting_changed", course: section.course.code, lesson: topic_key)
  rescue ActiveRecord::StaleObjectError
    redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_stale")
  rescue ActiveRecord::RecordInvalid
    redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_invalid")
  end

  # The other half of a lesson's integrity settings: what a student may do with
  # an AI assistant here. Audited, unlike a rename — this one changes what a
  # learner is permitted to do, and being able to show when the rule changed is
  # the point of writing it down.
  def update_ai_policy
    section = Section.for_staff(Current.user)
    topic_key = params[:topic_key].to_s

    unless section && Syllabus.topic_keys(section.course.code).include?(topic_key)
      return redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_forbidden")
    end

    LessonAiPolicy.transaction do
      policy = LessonAiPolicy.update!(course: section.course, topic_key:, use_key: params[:use_key].to_s,
                                      stance: params[:stance].to_s,
                                      expected_lock_version: params[:lock_version])
      # `stance`, never `to_state`: AuditEvent#interpolations treats from_state
      # and to_state as reserved and resolves them through
      # `admin.features.state.*`, which is right for the on/off switch beside
      # this one and nonsense for an already-localized stance.
      AuditEvent.record("lesson_ai_policy_changed", course: section.course.code, topic: topic_key,
                        use: policy.use_name, stance: policy.stance_name)
    end

    redirect_to instructor_path(tab: :integrity), notice: t("flash.ai_policy_changed")
  rescue ActiveRecord::StaleObjectError
    redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_stale")
  rescue ActiveRecord::RecordInvalid
    redirect_to instructor_path(tab: :integrity), alert: t("flash.integrity_setting_invalid")
  end

# A teacher's course, and the two things they may do to it (ADR-0054).
#
# Both are scoped by `taught_by?` rather than by the role: `allow_only :staff`
# opens this screen, and teaching *this* course is what opens its course. An
# administrator holds the staff role and reaches nothing here that is not
# theirs to teach — they have the console for that.
def update_course
  course = teachable_course
  return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course
  # Not while it is published. A credit count changing under enrolled students
  # is a lifecycle-shaped change, and it goes through the queue like the rest.
  return redirect_to instructor_path(tab: :course), alert: t("flash.course_not_editable") unless course.draft?

  Course.transaction do
    course.update!(course_params)
    AuditEvent.record("course_updated", course: course.code)
  end

  redirect_to instructor_path(tab: :course), notice: t("flash.course_updated", course: course.code)
rescue ActiveRecord::RecordInvalid => invalid
  redirect_to instructor_path(tab: :course), alert: invalid.record.errors.full_messages.to_sentence
end

# A request, never a transition. The administrator who decides it is the second
# pair of eyes ADR-0013 bought, and `approvable_by?` still refuses anybody
# their own request.
def request_course_transition
  course = teachable_course
  return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course

  ApprovalRequest.create_course_lifecycle!(course:, requester: Current.user,
                                           from_state: course.lifecycle_state,
                                           to_state: params[:state], note: params[:note])

  redirect_to instructor_path(tab: :course), notice: t("flash.approval_requested", course: course.code)
rescue ActiveRecord::RecordInvalid => invalid
  redirect_to instructor_path(tab: :course), alert: invalid.record.errors.full_messages.to_sentence
end

# The syllabus a teacher may shape, and the two shapes they may give it.
#
# Same gate as the course numbers above: their own course, and only while it is a
# draft. A published course's lessons change through the queue like everything
# else a learner can already see.
#
# Neither writes an audit event, for the reason AuditEvent gives for leaving the
# landing page's card reorder out of ACTIONS: these change neither what exists nor
# who can do what, and they are the noisiest controls a teacher has. Six clicks of
# ↑ would be six rows, and a log full of them buries the role grants. Adding and
# removing a lesson *does* change what exists — which is the other half of why
# that goes through the queue, where every decision is recorded.
def rename_topic
  with_draft_course do |course|
    names = params.fetch(:names, {}).permit(*I18n.available_locales.map(&:to_s)).to_h
    unless SyllabusBuilder.new(course).rename!(params[:topic_key], names)
      return redirect_to instructor_path(tab: :syllabus), alert: t("flash.topic_not_yours")
    end

    redirect_to instructor_path(tab: :syllabus), notice: t("flash.topic_renamed")
  end
rescue ActiveRecord::RecordInvalid
  redirect_to instructor_path(tab: :syllabus), alert: t("flash.topic_name_blank")
end

def move_topic
  with_draft_course do |course|
    unless SyllabusBuilder.new(course).move!(params[:topic_key], params[:direction])
      return redirect_to instructor_path(tab: :syllabus), alert: t("flash.topic_not_moved")
    end

    redirect_to instructor_path(tab: :syllabus), notice: t("flash.topic_moved")
  end
# Two moves in one module at the same moment both step out of the way through
# `SyllabusBuilder::PARKED`, and the unique index on (course_module_id, position)
# refuses the second. The transaction has already rolled it back, so the syllabus
# is intact and the honest answer is that this move did not happen.
rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
  redirect_to instructor_path(tab: :syllabus), alert: t("flash.topic_not_moved")
end

# A request, never a write. Adding a lesson changes what exists, so it goes to
# the queue exactly as publishing does — and `approvable_by?` still refuses
# anybody their own request, which is the whole reason the queue is there.
#
# Not gated on `draft?`: asking for a lesson in a published course is a
# reasonable thing to ask, and the administrator deciding it is the check.
def request_lesson
  course = teachable_course
  return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course

  ApprovalRequest.create_lesson_addition!(
    course:, requester: Current.user, module_number: params[:module_number],
    topic_kind: params[:topic_kind], minutes: params[:minutes],
    names: params.fetch(:names, {}).permit(*I18n.available_locales.map(&:to_s)).to_h,
    note: params[:note]
  )

  redirect_to instructor_path(tab: :syllabus), notice: t("flash.lesson_requested", course: course.code)
rescue ActiveRecord::RecordInvalid
  redirect_to instructor_path(tab: :syllabus), alert: t("flash.lesson_request_invalid")
end

# Retiring a lesson takes it out of the syllabus without taking it out of
# anybody's history (ADR-0055), and like every other change to what exists, an
# administrator decides it.
def request_retirement
  course = teachable_course
  return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course

  ApprovalRequest.create_lesson_retirement!(course:, requester: Current.user,
                                            topic_key: params[:topic_key], note: params[:note])

  redirect_to instructor_path(tab: :syllabus), notice: t("flash.retirement_requested")
rescue ActiveRecord::RecordInvalid
  redirect_to instructor_path(tab: :syllabus), alert: t("flash.retirement_request_invalid")
end

# And putting one back. ADR-0055 left restoration out and said what it would be
# when somebody wanted it: a second request kind, not a button. This is that.
def request_restoration
  course = teachable_course
  return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course

  ApprovalRequest.create_lesson_restoration!(course:, requester: Current.user,
                                             topic_key: params[:topic_key], note: params[:note])

  redirect_to instructor_path(tab: :syllabus), notice: t("flash.restoration_requested")
rescue ActiveRecord::RecordInvalid
  redirect_to instructor_path(tab: :syllabus), alert: t("flash.restoration_request_invalid")
end

  # The export the screen's button points at. Same gate as the screen; staff
  # with no section have nothing to download and go back to the notice that
  # says so.
  def grades
    section = Section.for_staff(Current.user)
    return redirect_to instructor_path if section.nil?

    report = InstructorReport.new(section)
    send_data report.grades_csv, filename: report.grades_filename,
                                 type: "text/csv; charset=utf-8", disposition: "attachment"
  end

  private
    # The gate both syllabus writes share: their course, and a draft. Spelled
    # once rather than at the head of each action, because the two answers a
    # teacher can get here — not yours, not while published — are the two
    # `update_course` already gives for the same reasons.
    def with_draft_course
      course = teachable_course
      return redirect_to instructor_path, alert: t("flash.course_not_yours") unless course
      unless course.draft?
        return redirect_to instructor_path(tab: :syllabus), alert: t("flash.course_not_editable")
      end

      yield course
    end

    # The course this staff account teaches, or nothing. `Section.for_staff` is
    # the same lookup the screen itself runs, and the instructor check is what
    # makes it this teacher's rather than any staff member's.
    def teachable_course
      section = Section.for_staff(Current.user)
      section&.course if section&.instructor_id == Current.user.id
    end

    # The numbers and the taxonomy. Not `code`, which is the identity every
    # locale key and completion row is joined by; not `lifecycle_state`, which
    # belongs to the queue; and not `learners` or `rating`, which are measured
    # rather than set.
    def course_params
      params.expect(course: [ :level, :credits, :projects, :hours, :core, :certificate, tags: [] ])
    end
end
