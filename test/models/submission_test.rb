require "test_helper"

# Grading, and what an attempt leaves behind. The rule worth holding onto is that
# a completion is only ever written by a pass — the browser has no say in it any
# more, which is the whole reason this table exists.
class SubmissionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @course = Course.find_by!(code: LessonContent::DEFAULT_COURSE)
    @topic = Topic.find_by!(key: Syllabus.topic_keys.first)
  end

  test "the quiz passes only on the right option" do
    assert LessonContent.grade_quiz(LessonContent::CORRECT_OPTION)[:passed]
    assert_not LessonContent.grade_quiz(LessonContent::CORRECT_OPTION + 1)[:passed]
    assert_not LessonContent.grade_quiz(nil)[:passed]
    assert_not LessonContent.grade_quiz("")[:passed]
  end

  # The answer arrives as a JSON number and as a form string depending on the
  # caller, so grading compares them the same way.
  test "the quiz grades a numeric and a string answer alike" do
    assert LessonContent.grade_quiz(1)[:passed]
    assert LessonContent.grade_quiz("1")[:passed]
  end

  test "the coding task reports each criterion, and passes only on all of them" do
    verdict = LessonContent.grade_code("x = 1")

    assert_not verdict[:passed]
    assert_equal [ false, false, false ], verdict[:checks]

    verdict = LessonContent.grade_code(<<~PYTHON)
      train_test_split(X, y, test_size=0.2, random_state=42)
    PYTHON

    assert verdict[:passed]
    assert_equal [ true, true, true ], verdict[:checks]
  end

  # The starter ships with ___ in it. Matching every pattern around an unfinished
  # line is not a pass.
  test "a leftover blank fails however well the rest matches" do
    verdict = LessonContent.grade_code(<<~PYTHON)
      train_test_split(X, y, test_size=0.2, random_state=42)
      z = ___
    PYTHON

    assert_equal [ true, true, true ], verdict[:checks]
    assert_not verdict[:passed]
  end

  test "a passing submission records the completion it earns" do
    assert_difference -> { TopicCompletion.count }, 1 do
      submission = record("quiz", LessonContent::CORRECT_OPTION)
      assert_predicate submission, :passed?
    end

    assert_predicate @user.topic_completions.sole, :persisted?
  end

  test "a failing submission is kept, and earns nothing" do
    assert_difference -> { Submission.count }, 1 do
      assert_no_difference -> { TopicCompletion.count } do
        assert_not_predicate record("quiz", 3), :passed?
      end
    end
  end

  test "every attempt is kept, so the failures can be counted" do
    3.times { record("quiz", 3) }
    record("quiz", LessonContent::CORRECT_OPTION)

    attempts = Submission.where(user: @user, topic: @topic, kind: "quiz")
    assert_equal 4, attempts.count
    assert_equal 1, attempts.passed.count
  end

  test "passing the coding task applies the topic the quiz learned" do
    record("quiz", LessonContent::CORRECT_OPTION)
    record("code", "train_test_split(X, y, test_size=0.2, random_state=42)")

    completion = @user.topic_completions.sole
    assert_predicate completion, :applied?
    assert_equal 1, @user.topic_completions.count, "one row, both stamps"
  end

  test "a kind the lesson does not hand out is rejected" do
    submission = Submission.new(user: @user, course: @course, topic: @topic,
                                kind: "essay", answer: "x", passed: true)

    assert_not_predicate submission, :valid?
  end

  # "0" is a legitimate quiz answer, so it must not be mistaken for nothing.
  test "the zero option is a real answer" do
    submission = Submission.new(user: @user, course: @course, topic: @topic,
                                kind: "quiz", answer: "0", passed: false)

    assert_predicate submission, :valid?
  end

  private
    def record(kind, answer)
      verdict = kind == "quiz" ? LessonContent.grade_quiz(answer) : LessonContent.grade_code(answer)

      Submission.record(user: @user, course: @course, topic: @topic, kind:, answer:, verdict:)
    end
end
