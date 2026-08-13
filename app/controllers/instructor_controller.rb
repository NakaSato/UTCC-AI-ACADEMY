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
  end

  def update_integrity_setting
    section = Section.for_staff(Current.user)
    topic_key = params[:topic_key].to_s

    unless section && Syllabus.topic_keys(section.course.code).include?(topic_key)
      redirect_to instructor_path, alert: t("flash.integrity_setting_forbidden")
      return
    end

    enabled = LessonIntegritySetting.parse_boolean(params[:enabled])
    unless !enabled.nil?
      redirect_to instructor_path, alert: t("flash.integrity_setting_invalid")
      return
    end

    previous = LessonIntegritySetting.find_by(course: section.course, topic_key:)&.enabled != false
    LessonIntegritySetting.transaction do
      LessonIntegritySetting.update!(course: section.course, topic_key:, enabled:,
                                     expected_lock_version: params[:lock_version])
      AuditEvent.record("lesson_integrity_setting_changed", course: section.course.code, topic: topic_key,
                        from_state: previous ? "on" : "off", to_state: enabled ? "on" : "off")
    end

    redirect_to instructor_path,
                notice: t("flash.lesson_integrity_setting_changed", course: section.course.code, lesson: topic_key)
  rescue ActiveRecord::StaleObjectError
    redirect_to instructor_path, alert: t("flash.integrity_setting_stale")
  rescue ActiveRecord::RecordInvalid
    redirect_to instructor_path, alert: t("flash.integrity_setting_invalid")
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
  return redirect_to instructor_path, alert: t("flash.course_not_editable") unless course.draft?

  Course.transaction do
    course.update!(course_params)
    AuditEvent.record("course_updated", course: course.code)
  end

  redirect_to instructor_path, notice: t("flash.course_updated", course: course.code)
rescue ActiveRecord::RecordInvalid => invalid
  redirect_to instructor_path, alert: invalid.record.errors.full_messages.to_sentence
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

  redirect_to instructor_path, notice: t("flash.approval_requested", course: course.code)
rescue ActiveRecord::RecordInvalid => invalid
  redirect_to instructor_path, alert: invalid.record.errors.full_messages.to_sentence
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
