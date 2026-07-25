class LessonsController < ApplicationController
  def show
    @step = LessonContent.step_for(params[:step])
  end
end
