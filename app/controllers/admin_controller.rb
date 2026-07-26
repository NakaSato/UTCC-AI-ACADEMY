class AdminController < ApplicationController
  allow_only :admin

  def show
    @tab = AdminConsole.tab_for(params[:tab])

    case @tab
    in :users
      # Both filters are whitelist-or-default; the search is a plain substring
      # over the two columns the roster shows.
      @role = AdminConsole.role_filter(params[:role])
      @query = params[:q].to_s.strip

      @users = User.order(:role, :name)
      @users = @users.where(role: @role) unless @role == :all
      if @query.present?
        needle = "%#{User.sanitize_sql_like(@query)}%"
        @users = @users.where("name LIKE :q OR student_id LIKE :q", q: needle)
      end
    in :sections then load_sections
    in :integrity then @cases = Proctoring.cases
    in :audit then @level = AdminConsole.level_filter(params[:level])
    in :courses then @query = params[:q].to_s.strip
    else nil
    end
  end

  # The three section writes. Each answers with a redirect back to the tab and
  # a flash, like #update below — no JSON, no partial responses. Validation
  # failures surface as the model's own messages, so the invariants (staff-only
  # instructor, student-only roster) read the same here as in the tests.
  def create_section
    section = Section.new(course: Course.find_by(code: params[:course_code].to_s),
                          code: params[:code].to_s.strip, term: params[:term].to_s.strip,
                          instructor: find_staff(params[:instructor_id]))

    if section.save
      redirect_to admin_path(tab: :sections, section: section.id),
                  notice: t("flash.section_created", label: section.label)
    else
      redirect_to admin_path(tab: :sections), alert: section.errors.full_messages.to_sentence
    end
  end

  def update_section
    section = Section.find(params[:id])

    if section.update(instructor: find_staff(params[:instructor_id]))
      redirect_to admin_path(tab: :sections, section: section.id),
                  notice: t("flash.section_updated", label: section.label)
    else
      redirect_to admin_path(tab: :sections, section: section.id),
                  alert: section.errors.full_messages.to_sentence
    end
  end

  def enrol
    section = Section.find(params[:id])
    student = User.find_by(student_id: params[:student_id].to_s.strip.downcase)

    if student.nil?
      redirect_to admin_path(tab: :sections, section: section.id), alert: t("flash.student_missing")
      return
    end

    enrollment = Enrollment.find_or_initialize_by(section:, user: student)
    fresh = enrollment.new_record?

    if enrollment.persisted? || enrollment.save
      # Only a new enrolment is news — re-submitting the form must not ping.
      Notification.notify(student, "enrolled", label: section.label) if fresh
      redirect_to admin_path(tab: :sections, section: section.id),
                  notice: t("flash.enrolled", name: student.name, label: section.label)
    else
      redirect_to admin_path(tab: :sections, section: section.id),
                  alert: enrollment.errors.full_messages.to_sentence
    end
  end

  def unenrol
    section = Section.find(params[:id])
    enrollment = section.enrollments.find_by!(user_id: params[:user_id])
    enrollment.destroy

    redirect_to admin_path(tab: :sections, section: section.id),
                notice: t("flash.unenrolled", name: enrollment.user.name, label: section.label)
  end

  # "Notify student": the learner hears their case was flagged, in their own
  # language when they read it.
  def notify_case
    subject = case_subject or return
    user, course = subject
    Notification.notify(user, "integrity_notice", course: course.code)

    redirect_to admin_path(tab: :integrity), notice: t("flash.case_notified", name: user.name)
  end

  # "Escalate": the instructor of the student's section for that course hears.
  # No section or no instructor is a flash, not a guess at someone else.
  def escalate_case
    subject = case_subject or return
    user, course = subject
    instructor = user.sections.find_by(course:)&.instructor

    if instructor.nil?
      redirect_to admin_path(tab: :integrity), alert: t("flash.no_instructor", name: user.name)
    else
      Notification.notify(instructor, "integrity_escalated", name: user.name, course: course.code)
      redirect_to admin_path(tab: :integrity), notice: t("flash.case_escalated", name: instructor.name)
    end
  end

  # Closing a case is stamping the learner's unreviewed events — there is no
  # case row, so there is nothing else to write. New events open a new case.
  def close_case
    user = User.find(params[:user_id])
    ProctorEvent.unreviewed.where(user:).update_all(reviewed_at: Time.current, updated_at: Time.current)

    redirect_to admin_path(tab: :integrity), notice: t("flash.integrity_closed", name: user.name)
  end

  def update
    user = User.find(params[:id])

    # An admin cannot change their own role. Only an admin reaches this action, so
    # that single rule is what guarantees the last admin cannot demote the site
    # into having none.
    if user == Current.user
      redirect_to admin_path, alert: t("flash.role_self")
    elsif user.update(role: params[:role])
      # The role key, not the sentence — the notification names the role in the
      # reader's language when it is read, not the granter's when it was given.
      Notification.notify(user, "role_changed", role: user.role)
      redirect_to admin_path,
                  notice: t("flash.role_changed", name: user.name, role: t("admin.roles.#{user.role}"))
    else
      redirect_to admin_path, alert: t("flash.role_invalid")
    end
  end
  private
    def load_sections
      @sections = Section.includes(:course, :instructor).order(:id).to_a
      # Selection is by lookup, so an unknown id falls back rather than raises.
      @selected = @sections.find { it.id == params[:section].to_i } || @sections.first
      @staff = User.where(role: %w[ instructor admin ]).order(:name)
    end

    # A case is a learner's unreviewed events; acting on one that closed under
    # you is a flash, not a crash.
    def case_subject
      user = User.find(params[:user_id])
      event = ProctorEvent.unreviewed.where(user:).newest_first.first

      if event.nil?
        redirect_to admin_path(tab: :integrity), alert: t("flash.case_gone")
        return nil
      end

      [ user, event.course ]
    end

    # The instructor select posts an id; anything that is not a staff member's
    # resolves to nil, and the model rejects a non-staff assignment anyway —
    # this just keeps the common case from round-tripping an error.
    def find_staff(id)
      id.present? ? User.where(role: %w[ instructor admin ]).find_by(id:) : nil
    end
end
