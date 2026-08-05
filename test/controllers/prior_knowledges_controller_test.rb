require "test_helper"

class PriorKnowledgesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a learner can mark a course topic known and reverse it" do
    topic = courses(:ai1101).topics.first

    assert_difference -> { users(:one).prior_knowledges.count }, 1 do
      post mark_topic_known_url(course: "AI1101", topic: topic.key)
    end

    assert_redirected_to knowledge_map_url(course: "AI1101", topic: topic.key, mode: "course")
    assert_equal I18n.t("flash.prior_knowledge_marked"), flash[:notice]

    assert_difference -> { users(:one).prior_knowledges.count }, -1 do
      delete unmark_topic_known_url(course: "AI1101", topic: topic.key, mode: "course")
    end

    assert_redirected_to knowledge_map_url(course: "AI1101", topic: topic.key, mode: "course")
    assert_equal I18n.t("flash.prior_knowledge_unmarked"), flash[:notice]
  end

  test "a project-mode request cannot create prior knowledge" do
    topic = courses(:ai1101).topics.first

    assert_no_difference -> { users(:one).prior_knowledges.count } do
      post mark_topic_known_url(course: "AI1101", topic: topic.key, mode: "project")
    end

    assert_redirected_to knowledge_map_url(course: "AI1101", topic: topic.key, mode: "project")
    assert_equal I18n.t("flash.prior_knowledge_invalid"), flash[:alert]
  end

  test "an unknown course or topic cannot create prior knowledge" do
    assert_no_difference "PriorKnowledge.count" do
      post mark_topic_known_url(course: "NOPE", topic: "1-1")
      post mark_topic_known_url(course: "AI1101", topic: "missing")
    end

    assert_equal I18n.t("flash.prior_knowledge_invalid"), flash[:alert]
  end
end
