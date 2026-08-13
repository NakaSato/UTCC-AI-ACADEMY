class CoursesController < ApplicationController
  def show
    @course = CourseCatalog.find(params[:code], user: Current.user)
    return redirect_to root_path, alert: t("flash.course_missing") unless @course

    done = progress.keys_for(@course.code)
    @modules = Syllabus.modules(done, @course.code)
    @open_module = (params[:module].presence || Syllabus.current_module_number(done, @course.code) || 1).to_i
    # One query, and only where the answer is used: whether this course has a
    # syllabus the PDF can render. Six of eight do not, and every one of them
    # offered the download anyway.
    @syllabus_available = ::Course.where(code: @course.code).joins(:course_modules).exists?
  end
end
