require "test_helper"

class PriorKnowledgeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @course = courses(:ai1101)
    @topic = @course.topics.first
  end

  test "a prior-knowledge mark is course-scoped and idempotent" do
    marked_at = 2.days.ago

    first = PriorKnowledge.mark(user: @user, course: @course, topic: @topic, at: marked_at)
    second = PriorKnowledge.mark(user: @user, course: @course, topic: @topic, at: Time.current)

    assert_equal first.id, second.id
    assert_equal marked_at.to_i, second.marked_at.to_i
    assert_equal 1, @user.prior_knowledges.count
  end

  test "a topic from another course is rejected" do
    other_topic = courses(:ai1102).topics.first
    mark = PriorKnowledge.new(user: @user, course: @course, topic: other_topic, marked_at: Time.current)

    assert_not mark.valid?
    assert_includes mark.errors[:topic], "must belong to the selected course"
  end

  test "a learner can reverse a prior-knowledge mark without changing completions" do
    mark = PriorKnowledge.mark(user: @user, course: @course, topic: @topic)
    completion_count = @user.topic_completions.count

    mark.destroy!

    assert_not @user.prior_knowledges.exists?(mark.id)
    assert_equal completion_count, @user.topic_completions.count
  end
end
