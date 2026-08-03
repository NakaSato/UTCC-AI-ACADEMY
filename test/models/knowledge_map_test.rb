require "test_helper"

class KnowledgeMapTest < ActiveSupport::TestCase
  test "curriculum maps expose each course's own modules and totals" do
    ai1101 = KnowledgeMap.curriculum("AI1101").first
    ai1102 = KnowledgeMap.curriculum("AI1102").first

    assert_equal 6, ai1101.children.size
    assert_equal 2, ai1102.children.size
    assert_equal Syllabus.topic_count("AI1101"), ai1101.total
    assert_equal Syllabus.topic_count("AI1102"), ai1102.total
    assert_not_equal ai1101.children.map(&:id), ai1102.children.map(&:id)
  end

  test "map mastery counts only the selected course's completions" do
    TopicCompletion.record(user: users(:one), course_code: "AI1102",
                           topic_key: Syllabus.topic_keys("AI1102").first, kind: :learned)

    ai1101 = KnowledgeMap.curriculum("AI1101", user: users(:one)).first
    ai1102 = KnowledgeMap.curriculum("AI1102", user: users(:one)).first

    assert_equal 0, ai1101.learned
    assert_equal 1, ai1102.learned
  end

  test "project mode includes sequential prerequisites for selected-course projects" do
    root = KnowledgeMap.curriculum("AI1102", mode: "project").first
    project = Syllabus.topics("AI1102").find { it.kind == "project" }
    project_node = root.children.flat_map(&:children).find { |node| node.topic_key == project.key }

    assert project_node
    assert_equal Syllabus.topic_keys("AI1102").first(4), project_node.prerequisite_keys
    assert_equal (Syllabus.topic_keys("AI1102").to_set),
                 root.children.flat_map(&:children).map(&:topic_key).to_set
  end

  test "invalid project nodes never resolve to another course" do
    root = KnowledgeMap.curriculum("AI1102", mode: "project").first

    assert_nil KnowledgeMap.find("1-1", nodes: [ root ])
    assert root.children.flat_map(&:children).all? { |node| node.course_code == "AI1102" }
  end

  test "a course without an owned curriculum has an empty safe map" do
    root = KnowledgeMap.curriculum("AI2402", user: users(:one)).first

    assert_equal "AI2402", root.course_code
    assert_equal 0, root.total
    assert_empty root.children
  end
end
