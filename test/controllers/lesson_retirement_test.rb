require "test_helper"

# Taking a lesson out of a syllabus without taking it out of anybody's history
# (ADR-0055). `topic.destroy` has never had a safe outcome — `topic_completions`
# and `prior_knowledges` are `dependent: :destroy` and `submissions` and
# `proctor_events` hold a foreign key — so removal is a retirement: the row
# stays, stops being offered, and stops counting toward a denominator.
class LessonRetirementTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:instructor)
    @course = Section.for_staff(@teacher).course
    @course.update!(lifecycle_state: "draft")
    @topic = topics(:topic_1_1)
    @student = users(:one)
    Syllabus.reload!
  end

  teardown { Syllabus.reload! }

  # ---- The request ----------------------------------------------------------

  test "a teacher asks, and asking retires nothing" do
    sign_in_as @teacher

    assert_difference "ApprovalRequest.count", 1 do
      post instructor_syllabus_retire_path(@topic.key)
    end

    assert_redirected_to instructor_path(tab: :syllabus)
    request = ApprovalRequest.newest_first.first
    assert_predicate request, :syllabus_lesson_retired?
    assert_not_predicate @topic.reload, :retired?
    assert_not request.approvable_by?(@teacher), "nobody decides their own request"
  end

  test "one pending retirement per lesson" do
    sign_in_as @teacher
    post instructor_syllabus_retire_path(@topic.key)

    assert_no_difference "ApprovalRequest.count" do
      post instructor_syllabus_retire_path(@topic.key)
    end
    assert_equal I18n.t("flash.retirement_request_invalid"), flash[:alert]
  end

  test "another teacher's lesson, and a lesson that is not a lesson, are refused" do
    sign_in_as @teacher

    assert_no_difference "ApprovalRequest.count" do
      post instructor_syllabus_retire_path("AI1102-1-1")
      post instructor_syllabus_retire_path("nonsense")
    end

    sign_in_as users(:console_instructor)
    assert_no_difference "ApprovalRequest.count" do
      post instructor_syllabus_retire_path(@topic.key)
    end
    assert_equal I18n.t("flash.course_not_yours"), flash[:alert]
  end

  test "a student reaches none of it" do
    sign_in_as @student
    post instructor_syllabus_retire_path(@topic.key)

    assert_redirected_to root_path
  end

  # ---- The decision ---------------------------------------------------------

  test "approving retires the lesson and destroys nothing" do
    completion = TopicCompletion.find_or_create_by!(user: @student, course: @course, topic: @topic) do
      it.learned_at = Time.current
    end
    sign_in_as @teacher
    post instructor_syllabus_retire_path(@topic.key)
    request = ApprovalRequest.newest_first.first

    assert_no_difference [ "Topic.count", "TopicCompletion.count" ] do
      request.decide!(actor: users(:admin), outcome: "approved")
    end

    assert_predicate @topic.reload, :retired?
    assert TopicCompletion.exists?(completion.id), "a retirement must not touch what a learner finished"
  end

  test "rejecting leaves the lesson where it is" do
    sign_in_as @teacher
    post instructor_syllabus_retire_path(@topic.key)

    ApprovalRequest.newest_first.first.decide!(actor: users(:admin), outcome: "rejected")

    assert_not_predicate @topic.reload, :retired?
  end

  test "the decision is audited as a retirement, not as a lifecycle move" do
    sign_in_as @teacher
    post instructor_syllabus_retire_path(@topic.key)
    ApprovalRequest.newest_first.first.decide!(actor: users(:admin), outcome: "approved")

    event = AuditEvent.newest_first.first
    assert_equal "lesson_retirement_decided", event.action
    assert_equal :warn, event.level
    assert_no_match(/[{}]/, event.text)
  end

  # ---- What retirement means ------------------------------------------------

  test "a retired lesson leaves the syllabus, and every denominator with it" do
    before = Syllabus.topic_count(@course.code)
    retire!

    assert_equal before - 1, Syllabus.topic_count(@course.code)
    assert_not_includes Syllabus.topic_keys(@course.code), @topic.key
    assert_not_includes Syllabus.keys_in(1, @course.code), @topic.key
    assert_not_includes Syllabus.modules(Set.new, @course.code).flat_map { it.topics.map(&:key) }, @topic.key
    assert_nil Syllabus.topic(@topic.key, @course.code)
  end

  # The half of ADR-0055 most likely to be undone by accident later.
  test "a learner keeps the lesson they finished before it was retired" do
    TopicCompletion.find_or_create_by!(user: @student, course: @course, topic: @topic) do
      it.learned_at = Time.current
    end
    retire!

    report = InstructorReport.new(Section.for_staff(@teacher))
    row = report.roster.find { it.user == @student }

    assert row.percent.positive?, "the completion still counts for the learner who earned it"
    assert_operator row.percent, :<=, 100, "and a numerator over its denominator is clamped, not printed"
  end

  # The panel answers "what should I fix next?" about the syllabus as it stands.
  # A lesson nobody is taught any more is not something to fix — its submissions
  # stay, and still count for the learners who made them.
  test "a retired lesson leaves the topics-students-struggle-with panel" do
    section = Section.for_staff(@teacher)
    section.students.each do
      Submission.create!(user: it, course: @course, topic: @topic, kind: "quiz", passed: false, answer: "x")
    end
    Syllabus.reload!
    assert_includes InstructorReport.new(section).hard_topics.map { it[:key] }, @topic.key

    retire!

    assert_not_includes InstructorReport.new(section).hard_topics.map { it[:key] }, @topic.key
    assert_equal section.students.size, Submission.where(topic: @topic).count,
                 "the submissions stay; only the panel stops asking about them"
  end

  test "a retired lesson is still nameable, because its history still points at it" do
    name = Syllabus.topic_name(@topic.key, @course.code)
    retire!

    assert_equal name, Syllabus.topic_name(@topic.key, @course.code),
                 "a completion and an integrity case still have to say which lesson they meant"
  end

  test "a retired lesson is not a lesson anybody can open" do
    retire!
    # Published, because that is the state a learner meets a course in — `draft`
    # in setup exists for the teacher's edit gate, and retirement is not gated on
    # it. A draft course answers `flash.course_missing` long before the topic is
    # ever resolved, which would make this test pass for the wrong reason.
    @course.update!(lifecycle_state: "published")
    sign_in_as @student

    get lesson_url(topic: @topic.key)

    assert_redirected_to course_path(@course.code)
    assert_equal I18n.t("flash.topic_missing"), flash[:alert]
  end

  test "the syllabus a learner is walked through skips it" do
    retire!

    assert_not_equal @topic.key, Syllabus.next_topic_key(Set.new, @course.code)
    assert_not_includes Syllabus.topic_keys(@course.code), Syllabus.topic_after(@topic.key, @course.code)
  end

  test "no route destroys a topic" do
    sources = Dir[Rails.root.join("app/{controllers,models}/**/*.rb")]
    offenders = sources.select { File.read(it).match?(/\.destroy\b/) && File.read(it).include?("Topic") }

    assert_empty offenders.grep(/syllabus_builder|instructor_controller/),
                 "removal is a retirement; nothing in this path may destroy a lesson"
  end

  private
    def retire!
      sign_in_as @teacher
      post instructor_syllabus_retire_path(@topic.key)
      ApprovalRequest.newest_first.first.decide!(actor: users(:admin), outcome: "approved")
      Syllabus.reload!
    end
end
