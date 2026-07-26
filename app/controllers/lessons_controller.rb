class LessonsController < ApplicationController
  # The lesson's two graded steps report a pass at most once each, and a student
  # who redoes a topic writes no second row — but nothing stops a script from
  # hammering it either.
  rate_limit to: 30, within: 3.minutes, only: :submit

  before_action :set_course, only: :show
  before_action :set_topic, only: :show

  def show
    @step = LessonContent.step_for(params[:step])
  end

  # Where the exercise and the coding task send what the student did. The server
  # grades it, files the attempt, and answers with the verdict the page renders —
  # so the answer key never leaves this side and a pass cannot be had by posting
  # one, which is what `complete` used to allow.
  #
  # JSON rather than a redirect: the caller is fetch(), not a form. The lock the
  # lesson screen enforces is checked again here, because a post does not have to
  # come from that screen.
  def submit
    kind = params[:kind].to_s
    return head :unprocessable_entity unless Submission::KINDS.include?(kind)

    course = Course.find_by(code: params[:course].to_s)
    topic = Topic.find_by(key: params[:topic].to_s)
    return head :unprocessable_entity unless course && topic
    return head :forbidden unless Syllabus.unlocked?(topic.key, progress.keys_for(course.code))

    verdict = grade(kind, params[:answer])
    Submission.record(user: Current.user, course:, topic:, kind:, answer: params[:answer], verdict:)

    # The progress screens count the rows when they next render; nothing here
    # reads back a total.
    render json: verdict
  end

  private
    def grade(kind, answer)
      kind == "quiz" ? LessonContent.grade_quiz(answer) : LessonContent.grade_code(answer)
    end

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
