class CoursesController < ApplicationController
  def show
    @course = CourseCatalog.find(params[:code], user: Current.user)
    return redirect_to root_path, alert: t("flash.course_missing") unless @course

    done = progress.keys_for(@course.code)
    @modules = Syllabus.modules(done, @course.code)
    @open_module = (params[:module].presence || Syllabus.current_module_number(done, @course.code) || 1).to_i
  end
end
