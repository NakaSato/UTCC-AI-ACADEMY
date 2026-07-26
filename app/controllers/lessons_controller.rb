class LessonsController < ApplicationController
  # The lesson's two graded steps report a pass at most once each, and a student
  # who redoes the lesson writes no second row — but nothing stops a script from
  # hammering it either.
  rate_limit to: 30, within: 3.minutes, only: :complete

  def show
    @step = LessonContent.step_for(params[:step])
  end

  # The lesson grades itself in the browser and reports the result here — see
  # rewards_controller.js. A determined student can therefore post a completion
  # they did not earn, exactly as they can already read the answer key out of the
  # page. Server-side grading fixes both, and this table was the missing half of
  # it: there was nowhere to write a submission to.
  def complete
    kind = params[:kind].to_s.to_sym
    return head :unprocessable_entity unless TopicCompletion::KINDS.include?(kind)

    completion = TopicCompletion.record(
      user: Current.user, kind:,
      course_code: LessonContent::COURSE_CODE, topic_key: LessonContent::TOPIC_KEY
    )
    return head :unprocessable_entity unless completion.persisted?

    # Nothing on the lesson screen reads the new totals — the sidebar counter has
    # already moved on its own, and the progress screens count the rows when they
    # next render.
    head :created
  end
end
