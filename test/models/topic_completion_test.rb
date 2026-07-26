require "test_helper"

# The recording half: what a completion will and will not accept, and that
# reporting the same pass twice writes one row.
class TopicCompletionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @key = Syllabus.topic_keys.first
  end

  test "a completion names a real course and a real topic" do
    completion = TopicCompletion.new(user: @user, course_code: "AI1101", topic_key: @key, learned_at: Time.current)
    assert_predicate completion, :valid?

    completion.course_code = "NOPE"
    assert_not_predicate completion, :valid?

    completion.course_code = "AI1101"
    completion.topic_key = "99-99"
    assert_not_predicate completion, :valid?
  end

  test "recording the same topic twice keeps one row and the first timestamp" do
    first = TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key,
                                   kind: :learned, at: 2.days.ago)
    again = TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key, kind: :learned)

    assert_equal first.id, again.id
    assert_equal 1, @user.topic_completions.count
    assert_in_delta first.learned_at, again.reload.learned_at, 1.second
  end

  test "applying a topic implies learning it, and does not overwrite when it happened" do
    learned_at = 3.days.ago
    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key, kind: :learned, at: learned_at)
    applied = TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key, kind: :applied)

    assert_predicate applied, :applied?
    assert_in_delta learned_at, applied.learned_at, 1.second

    # Applying first writes both stamps at once — a topic cannot be applied
    # without having been learned.
    fresh = TopicCompletion.record(user: users(:two), course_code: "AI1101",
                                   topic_key: @key, kind: :applied)
    assert_predicate fresh, :applied?
    assert_predicate fresh.learned_at, :present?
  end

  test "two learners can complete the same topic" do
    TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key, kind: :learned)
    other = TopicCompletion.record(user: users(:two), course_code: "AI1101", topic_key: @key, kind: :learned)

    assert_predicate other, :persisted?
  end

  test "a day is active from either stamp" do
    completion = TopicCompletion.record(user: @user, course_code: "AI1101", topic_key: @key,
                                        kind: :learned, at: 2.days.ago)
    assert_equal 1, completion.active_days.size

    completion.update!(applied_at: Time.current)
    assert_equal 2, completion.active_days.size
  end
end
