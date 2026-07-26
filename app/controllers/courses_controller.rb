class CoursesController < ApplicationController
  def show
    @course = CourseCatalog.find(params[:code], user: Current.user)
    return redirect_to root_path, alert: t("flash.course_missing") unless @course

    # Only AI1101 has a syllabus written out; every other course reuses it as
    # placeholder structure until real modules land. The learner's finished
    # topics are what decides which modules read as done, current and locked.
    done = progress.keys_for(@course.code)
    @modules = Syllabus.modules(done)
    @open_module = (params[:module].presence || Syllabus.current_module_number(done) || 1).to_i
  end
end
