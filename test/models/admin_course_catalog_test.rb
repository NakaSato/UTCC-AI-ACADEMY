require "test_helper"

class AdminCourseCatalogTest < ActiveSupport::TestCase
  test "course rows use persisted course and cohort records" do
    row = AdminConsole.courses.find { it.code == "AI1101" }

    assert_equal courses(:ai1101), row.record
    assert_equal 1, row.sections
    assert_equal 2, row.students
    assert_equal I18n.t("catalog.courses.AI1101.title"), row.name
  end

  test "a course with no sections is still represented with zero counts" do
    row = AdminConsole.courses.find { it.code == "AI1102" }

    assert_equal 0, row.sections
    assert_equal 0, row.students
  end

  test "catalog visibility follows lifecycle state" do
    course = courses(:ai1101)
    course.update!(lifecycle_state: :archived)

    assert_not_includes CourseCatalog.codes, course.code
    assert_includes CourseCatalog.codes, courses(:ai1102).code
  end

  test "a learner with progress retains access to an archived course" do
    user = users(:one)
    TopicCompletion.record(user:, course_code: "AI1101", topic_key: "1-1", kind: :learned)
    courses(:ai1101).update!(lifecycle_state: :archived)

    assert CourseCatalog.find("AI1101", user:)
  end
end
