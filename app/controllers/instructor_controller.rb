class InstructorController < ApplicationController
  allow_only :staff

  def show
    @section = Section.for_staff(Current.user)

    # Staff with nothing to teach, and no section in the database to fall back
    # on: the screen says so rather than averaging over an empty roster.
    @report = InstructorReport.new(@section) if @section
    @integrity_settings = LessonIntegritySetting.rows_for(@section.course) if @section
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
end
