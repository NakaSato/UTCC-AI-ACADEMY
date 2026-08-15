class LessonsController < ApplicationController
  # The lesson's two graded steps report a pass at most once each, and a student
  # who redoes a topic writes no second row — but nothing stops a script from
  # hammering it either.
  rate_limit to: 30, within: 3.minutes, only: :submit
  # Incidents can fire in bursts — a flurry of tab switches is exactly the
  # signal — so the ceiling is looser than grading's.
  rate_limit to: 60, within: 3.minutes, only: :incident

  before_action :set_course, only: :show
  before_action :set_topic, only: :show

  def show
    @step = LessonContent.step_for(params[:step])
    @lesson_content = LessonContent.for(@topic_key)
    @course_record = Course.find_by!(code: @course.code)
    events = proctor_events
    @proctor_score = Proctoring.score_for_counts(events.group(:kind).count)
    @proctor_log_entries = Proctoring.log_entries(events.newest_first.limit(Proctoring::MAX_EVENTS))
    @show_integrity_log = Current.user.student? && LessonIntegritySetting.enabled?(course: @course_record,
                                                                                     topic_key: @topic_key)
    # Shown to everyone, staff included: a teacher reading their own lesson
    # should see the rule their students are being held to.
    @ai_policies = LessonAiPolicy.rows_for(course: @course_record, topic_key: @topic_key)
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
    topic = course&.topics&.find_by(key: params[:topic].to_s)
    return head :unprocessable_entity unless course && topic
    return head :forbidden unless Syllabus.unlocked?(topic.key, progress.keys_for(course.code), course.code)

    verdict = grade(kind, params[:answer], topic.key)
    Submission.record(user: Current.user, course:, topic:, kind:, answer: params[:answer], verdict:)

    # The progress screens count the rows when they next render; nothing here
    # reads back a total.
    render json: verdict
  end

  # The proctor reporting one incident. Whitelist-or-nothing like every param,
  # but no lock check on purpose: the report is evidence against the reporter,
  # and forging evidence against yourself is not a threat worth code.
  def incident
    kind = params[:kind].to_s
    return head :unprocessable_entity unless ProctorEvent::KINDS.include?(kind)

    step = params[:step].to_s
    return head :unprocessable_entity unless Proctoring::ACTIVE_STEPS.include?(step)

    course = Course.find_by(code: params[:course].to_s)
    topic = course&.topics&.find_by(key: params[:topic].to_s)
    return head :unprocessable_entity unless course && topic

    ProctorEvent.create!(user: Current.user, course:, topic:, kind:, occurred_at: Time.current)
    head :created
  end

  private
    def grade(kind, answer, topic_key)
      content = LessonContent.for(topic_key)
      kind == "quiz" ? content.grade_quiz(answer) : content.grade_code(answer)
    end

    def proctor_events
      return ProctorEvent.none unless Current.user.student?

      topic = @course_record.topics.find_by(key: @topic_key)
      return ProctorEvent.none unless topic

      ProctorEvent.where(user: Current.user, course: @course_record, topic:)
    end

    def set_course
      @course = CourseCatalog.find(params[:course].presence || LessonContent::DEFAULT_COURSE, user: Current.user)

      redirect_to root_path, alert: t("flash.course_missing") unless @course
    end

    # No `?topic=` means "carry on": the first topic of this course not yet
    # finished, or the last one once they all are.
    def set_topic
      @topic_key = params[:topic].presence || @course.next_key || Syllabus.topic_keys(@course.code).last

      return if Syllabus.unlocked?(@topic_key, progress.keys_for(@course.code), @course.code)

      redirect_to course_path(@course.code),
                  alert: t(Syllabus.topic_keys(@course.code).include?(@topic_key) ? "flash.topic_locked" : "flash.topic_missing")
    end
end
