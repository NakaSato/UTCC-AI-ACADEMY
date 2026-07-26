class LessonsController < ApplicationController
  # The lesson's two graded steps report a pass at most once each, and a student
  # who redoes a topic writes no second row — but nothing stops a script from
  # hammering it either.
  rate_limit to: 30, within: 3.minutes, only: :complete

  before_action :set_course, only: :show
  before_action :set_topic, only: :show

  def show
    @step = LessonContent.step_for(params[:step])
  end

  # The lesson grades itself in the browser and reports the result here — see
  # rewards_controller.js. A determined student can therefore post a completion
  # they did not earn, exactly as they can already read the answer key out of the
  # page. Server-side grading fixes both, and this is where it would go.
  #
  # Answers as status rather than as a redirect: the caller is fetch(), not a
  # form. The same lock the lesson screen enforces is checked again here, since
  # a post does not have to come from that screen.
  def complete
    kind = params[:kind].to_s.to_sym
    code, key = params[:course].to_s, params[:topic].to_s

    return head :unprocessable_entity unless TopicCompletion::KINDS.include?(kind)
    return head :forbidden unless Syllabus.unlocked?(key, progress.keys_for(code))

    completion = TopicCompletion.record(user: Current.user, course_code: code, topic_key: key, kind:)
    return head :unprocessable_entity unless completion.persisted?

    # Nothing on the lesson screen reads the new totals — the sidebar counter has
    # already moved on its own, and the progress screens count the rows when they
    # next render.
    head :created
  end

  private
    def set_course
      @course = CourseCatalog.find(params[:course].presence || LessonContent::DEFAULT_COURSE, user: Current.user)

      redirect_to root_path, alert: t("flash.course_missing") unless @course
    end

    # No `?topic=` means "carry on": the first topic of this course not yet
    # finished, or the last one once they all are.
    def set_topic
      @topic_key = params[:topic].presence || @course.next_key || Syllabus.topic_keys.last

      return if Syllabus.unlocked?(@topic_key, progress.keys_for(@course.code))

      redirect_to course_path(@course.code),
                  alert: t(Syllabus.topic_keys.include?(@topic_key) ? "flash.topic_locked" : "flash.topic_missing")
    end
end
