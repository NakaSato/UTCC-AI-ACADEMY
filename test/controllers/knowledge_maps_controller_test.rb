require "test_helper"

class KnowledgeMapsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the selected course controls map shape and lesson links" do
    get knowledge_map_url(course: "AI1102", topic: "AI1102-1-1")

    assert_response :success
    assert_select "h2", text: Syllabus.modules(Set.new, "AI1102").first.topics.first.name
    assert_select "a[href=?]", lesson_path(course: "AI1102", topic: "AI1102-1-1")
    assert_select "a[href=?]", lesson_path(course: "AI1101", topic: "1-1"), count: 0
  end

  test "an unknown course topic falls back within the selected course" do
    get knowledge_map_url(course: "AI1102", topic: "1-1")

    assert_response :success
    assert_select "h2", text: Syllabus.modules(Set.new, "AI1102").first.topics.first.name
    assert_no_match(/#{Regexp.escape(Syllabus.modules(Set.new, "AI1101").first.topics.first.name)}/, response.body)
  end

  test "project mode removes non-functional controls" do
    project_key = Syllabus.topics("AI1102").find { it.kind == "project" }.key
    get knowledge_map_url(course: "AI1102", mode: "project", topic: project_key)

    assert_response :success
    assert_no_match(/#{Regexp.escape(I18n.t("map.mark_known"))}/, response.body)
    assert_no_match(/#{Regexp.escape(I18n.t("map.settings_label"))}/, response.body)
    assert_select "[data-map-prerequisites] li", count: 4
    assert_select "[data-map-total]", text: "5"
  end

  test "map totals reflect selected-course mastery" do
    TopicCompletion.record(user: users(:one), course_code: "AI1102",
                           topic_key: Syllabus.topic_keys("AI1102").first, kind: :learned)

    get knowledge_map_url(course: "AI1102")

    assert_select "[data-map-total]", text: "5"
    assert_select "[data-map-learned]", text: "1"
  end

  test "an unmodeled course never renders another course's map topics" do
    get knowledge_map_url(course: "AI2402")

    assert_response :success
    assert_select "a[href=?]", lesson_path(course: "AI2402", topic: "1-1"), count: 0
    assert_no_match(/#{Regexp.escape(Syllabus.modules(Set.new, "AI1101").first.topics.first.name)}/, response.body)
  end

  test "unknown course and mode parameters fall back safely" do
    get knowledge_map_url(course: "NOPE", mode: "graph", topic: "AI1102-1-1")

    assert_response :success
    assert_select "h2", text: Syllabus.modules(Set.new, "AI1101").first.topics.first.name
    assert_select "a[aria-current=page]", text: I18n.t("map.modes.course")
    assert_select "a[href=?]", lesson_path(course: "AI1102", topic: "AI1102-1-1"), count: 0
  end
end
