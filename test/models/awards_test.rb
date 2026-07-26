require "test_helper"

# The award shelf, now that each award is a rule over real rows instead of a
# frozen earned-flag. One test per rule, plus the shape the two shelves share.
class AwardsTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "a new account has earned nothing, and every award still has its copy" do
    awards = progress.awards

    assert_equal 8, awards.size
    assert awards.none? { it[:earned] }
    assert awards.all? { it[:name].present? && it[:hint].present? && it[:glyph].present? }
  end

  test "the dashboard shelf is the first six of the same awards" do
    assert_equal progress.awards.first(6), progress.dashboard_badges
  end

  test "First Steps takes ten topics" do
    learn(9)
    assert_not earned?("◆")

    learn(10)
    assert earned?("◆")
  end

  test "Model Builder takes an applied project topic" do
    project = Syllabus.topics.find { it.kind == "project" }.key
    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: project, kind: :learned)
    assert_not earned?("▲"), "learning the project topic is not submitting it"

    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: project, kind: :applied)
    assert earned?("▲")
  end

  test "the streak award is the longest run ever, not the current streak" do
    # Seven consecutive days, ended a month ago: the current streak is 0 but
    # the run happened.
    7.times do |index|
      TopicCompletion.record(user: @user, course_code: "AI1101",
                             topic_key: Syllabus.topic_keys[index], kind: :learned,
                             at: (37 - index).days.ago)
    end

    assert_equal 0, progress.streak
    assert earned?("✦")
  end

  test "Deep Diver takes a whole module in one day" do
    Syllabus.keys_in(1).each do |key|
      TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: key, kind: :learned)
    end

    assert earned?("◈")
  end

  test "a module spread over two days is not Deep Diver" do
    keys = Syllabus.keys_in(1)
    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: keys.first,
                           kind: :learned, at: 1.day.ago)
    keys.drop(1).each do |key|
      TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: key, kind: :learned)
    end

    assert_not earned?("◈")
  end

  test "Helping Hand is unearnable until a forum records an answer" do
    learn(Syllabus.topic_count)

    assert_not earned?("✚")
  end

  test "Persistent takes three fails before the pass" do
    topic = Topic.find_by!(key: Syllabus.topic_keys.first)
    course = Course.find_by!(code: "AI1101")

    2.times { Submission.create!(user: @user, course:, topic:, kind: "quiz", answer: "3", passed: false) }
    Submission.create!(user: @user, course:, topic:, kind: "quiz", answer: "1", passed: true)
    assert_not earned?("♦"), "two fails is not persistence yet"

    Submission.create!(user: @user, course:, topic:, kind: "code", answer: "x", passed: false)
    3.times { Submission.create!(user: @user, course:, topic:, kind: "code", answer: "x", passed: false) }
    Submission.create!(user: @user, course:, topic:, kind: "code", answer: "ok", passed: true)
    assert earned?("♦")
  end

  test "the badge counts follow the shelf" do
    # Ten topics in one sitting is two awards: First Steps, and Deep Diver for
    # the modules that closed inside the same day.
    learn(10)

    assert_equal 2, progress.awards_earned
    assert_equal 8, progress.awards_total
  end

  test "the projects tile counts applied project topics" do
    assert_equal 0, progress.projects_done

    learn(1) # starts the course, so the denominator exists
    assert_equal 1, progress.projects_total

    project = Syllabus.topics.find { it.kind == "project" }.key
    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: project, kind: :applied)
    assert_equal 1, progress.projects_done
  end

  test "certificates count completed certificate courses" do
    assert_equal 0, progress.certificates_earned
    assert_operator progress.certificates_total, :>, 0

    Syllabus.topic_keys.each do |key|
      TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: key, kind: :learned)
    end

    assert_equal 1, progress.certificates_earned
  end

  test "hearts derive from recent failures, gate nothing, and grow back" do
    assert_equal 5, progress.hearts

    2.times { attempt_quiz(passed: false) }
    assert_equal 3, progress.hearts

    # A pass costs nothing, and an old failure has already grown back.
    attempt_quiz(passed: true)
    Submission.create!(user: @user, course: course_record, topic: topic_record,
                       kind: "quiz", answer: "3", passed: false,
                       created_at: 5.hours.ago, updated_at: 5.hours.ago)
    assert_equal 3, progress.hearts

    refill = progress.heart_refill_at
    assert_in_delta 4.hours.from_now.to_f, refill.to_f, 60
  end

  test "hearts clamp at zero however badly it goes" do
    8.times { attempt_quiz(passed: false) }

    assert_equal 0, progress.hearts
  end

  private
    def course_record = Course.find_by!(code: "AI1101")
    def topic_record = Topic.find_by!(key: Syllabus.topic_keys.first)

    def attempt_quiz(passed:)
      Submission.create!(user: @user, course: course_record, topic: topic_record,
                         kind: "quiz", answer: passed ? "1" : "3", passed:)
    end

    # A fresh instance per call: LearnerProgress memoises its rows, and these
    # tests write between reads.
    def progress = LearnerProgress.new(@user.reload)

    def earned?(glyph) = progress.awards.find { it[:glyph] == glyph }[:earned]

    def learn(count)
      Syllabus.topic_keys.first(count).each do |key|
        TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: key, kind: :learned)
      end
    end
end
