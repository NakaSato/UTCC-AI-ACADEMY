class CoursesController < ApplicationController
  def show
    @course = CourseCatalog.find(params[:code])
    return redirect_to root_path, alert: t("flash.course_missing") unless @course

    # Only AI1101 has a syllabus written out; every other course reuses it as
    # placeholder structure until real modules land.
    @modules = Syllabus.modules
    @open_module = (params[:module].presence || Syllabus::DEFAULT_OPEN).to_i
  end
end
