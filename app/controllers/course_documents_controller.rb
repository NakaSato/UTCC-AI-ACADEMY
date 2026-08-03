class CourseDocumentsController < ApplicationController
  def syllabus
    course = Course.find_by(code: params[:code])
    return head :not_found unless course&.course_modules&.exists?

    locale = I18n.locale
    send_data CourseSyllabusPdf.render(course:, locale:),
              filename: CourseSyllabusPdf.filename(course:, locale:),
              type: "application/pdf",
              disposition: "attachment"
  end
end
