require "application_system_test_case"

class KnowledgeMapWalkTest < ApplicationSystemTestCase
  test "a learner can walk two course-scoped knowledge maps" do
    sign_in_through_the_form(users(:one))

    visit knowledge_map_path(course: "AI1101", topic: Syllabus.topic_keys("AI1101").first)
    assert_text I18n.t("catalog.courses.AI1101.title", locale: :th)
    assert_selector "a[href='#{lesson_path(course: "AI1101", topic: "1-1")}']"

    visit knowledge_map_path(course: "AI1102", topic: "AI1102-1-1")
    assert_text I18n.t("catalog.courses.AI1102.title", locale: :th)
    assert_selector "a[href='#{lesson_path(course: "AI1102", topic: "AI1102-1-1")}']"
  end
end
