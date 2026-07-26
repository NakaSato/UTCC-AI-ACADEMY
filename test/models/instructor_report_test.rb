require "test_helper"

# The Teaching console, now that it is a report on a real section rather than a
# module of invented figures. The case that matters most is the last one: the
# roster is the section, not the user table.
class InstructorReportTest < ActiveSupport::TestCase
  setup do
    @section = sections(:ba_2)
    @report = InstructorReport.new(@section)
    @course = @section.course
    @topic = Topic.find_by!(key: Syllabus.topic_keys.first)
  end

  test "the roster is the section's students, not everybody" do
    assert_equal 2, @report.size
    assert_equal [ users(:one), users(:student) ].map(&:name).sort, @report.roster.map(&:name).sort
    assert_not_includes @report.roster.map(&:name), users(:two).name,
                        "users(:two) is not enrolled and must not appear"
  end

  test "progress is counted off the learner's own completions" do
    learn(users(:one), Syllabus.topic_keys.first(3))

    row = row_for(users(:one))
    assert_equal 3, (Syllabus.topic_count * row.percent / 100.0).round
    assert_equal 0, row_for(users(:student)).percent
  end

  # Furthest along first, so the students worth following up sit together at the
  # bottom where they are easy to find.
  test "the roster is ordered by progress" do
    learn(users(:student), Syllabus.topic_keys.first(4))

    assert_equal users(:student).name, @report.roster.first.name
  end

  test "a learner who has done nothing reads as never seen, not as seen today" do
    assert_nil row_for(users(:one)).seen
    assert_equal I18n.t("instructor.seen.never"), row_for(users(:one)).seen_text
  end

  test "last seen counts from the most recent completion or submission" do
    TopicCompletion.record(user: users(:one), course_code: @course.code,
                           topic_key: @topic.key, kind: :learned, at: 3.days.ago)

    assert_equal 3, row_for(users(:one)).seen
    assert_equal I18n.t("instructor.seen.days_ago", count: 3), row_for(users(:one)).seen_text
  end

  test "an attempt counts as being seen even when it failed" do
    Submission.create!(user: users(:one), course: @course, topic: @topic,
                       kind: "quiz", answer: "3", passed: false)

    assert_equal 0, row_for(users(:one)).seen
    assert_equal I18n.t("instructor.seen.today"), row_for(users(:one)).seen_text
  end

  test "standing follows the thresholds" do
    learn(users(:one), Syllabus.topic_keys.first((Syllabus.topic_count * 0.6).ceil))

    assert_predicate row_for(users(:one)), :on_track?
    assert_predicate row_for(users(:student)), :behind?
  end

  # The figure this table was built for: a topic everybody eventually passes can
  # still be the one everybody gets wrong first.
  test "hard topics count first attempts that failed" do
    fail_then_pass(users(:one), @topic)
    attempt(users(:student), @topic, passed: false)

    hardest = @report.hard_topics.first
    assert_equal @topic.key, hardest[:key]
    assert_equal 100, hardest[:percent], "both learners got it wrong first"
    assert_equal :alarm, hardest[:severity]
  end

  test "only the first attempt at a topic counts against it" do
    fail_then_pass(users(:one), @topic)
    attempt(users(:student), @topic, passed: true)

    assert_equal 50, @report.hard_topics.first[:percent], "one of two failed first"
  end

  test "a topic nobody gets wrong is not listed as hard" do
    attempt(users(:one), @topic, passed: true)

    assert_empty @report.hard_topics
  end

  test "severity escalates with the failure rate" do
    assert_equal :alarm, severity_at(100)
    assert_equal :warn, severity_at(45)
    assert_equal :notice, severity_at(20)
  end

  test "the cohort figures are averages over the roster" do
    learn(users(:one), Syllabus.topic_keys.first(Syllabus.topic_count))

    assert_equal 50, @report.average_percent, "one learner at 100%, one at 0"
    assert_equal 1, @report.inactive_count, "the one who has done nothing"
  end

  test "an empty section averages zero rather than dividing by it" do
    empty = Section.create!(course: @course, code: "BA-9", term: "1/2569")
    report = InstructorReport.new(empty)

    assert_equal 0, report.size
    assert_equal 0, report.average_percent
    assert_equal 0, report.on_time_percent
    assert_empty report.hard_topics
  end

  private
    def row_for(user) = @report.roster.find { it.name == user.name }

    def learn(user, keys)
      keys.each { TopicCompletion.record(user:, course_code: @course.code, topic_key: it, kind: :learned) }
    end

    def attempt(user, topic, passed:)
      Submission.create!(user:, course: @course, topic:, kind: "quiz",
                         answer: passed ? LessonContent::CORRECT_OPTION.to_s : "3", passed:)
    end

    def fail_then_pass(user, topic)
      attempt(user, topic, passed: false)
      attempt(user, topic, passed: true)
    end

    def severity_at(percent)
      InstructorReport.new(@section).send(:severity_for, percent)
    end
end
