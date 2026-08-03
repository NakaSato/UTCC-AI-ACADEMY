require "test_helper"

class AdminCoursesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the Courses tab lists persisted courses and counts" do
    get admin_url(tab: :courses)

    assert_response :success
    assert_select "main", text: /#{Regexp.escape(I18n.t("catalog.courses.AI1101.title"))}/
    assert_select "main", text: /AI1150/, count: 0
    assert_select "main", text: /#{I18n.t("admin.courses.th_sections")}/
    assert_select "main", text: /#{I18n.t("admin.courses.th_students")}/
  end

  test "publishing and archiving write one complete audit event" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "archived" }

    assert_redirected_to admin_path(tab: :courses)
    assert_predicate course.reload, :archived?
    event = AuditEvent.sole
    assert_equal "course_state_changed", event.action
    assert_equal users(:admin), event.user
    assert_equal({ "course" => "AI1101", "from" => "published", "to" => "archived" }, event.params)
    assert_equal :warn, event.level
  end

  test "an invalid transition changes neither course nor audit log" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "draft" }

    assert_redirected_to admin_path(tab: :courses)
    assert_equal I18n.t("flash.course_state_invalid"), flash[:alert]
    assert_predicate course.reload, :published?
    assert_empty AuditEvent.all
  end

  test "a stale transition changes neither course nor audit log" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "archived", from: "draft" }

    assert_redirected_to admin_path(tab: :courses)
    assert_predicate course.reload, :published?
    assert_empty AuditEvent.all
  end

  test "a non-admin cannot mutate course state" do
    sign_in_as users(:student)

    patch admin_course_state_url(courses(:ai1101)), params: { state: "archived" }

    assert_redirected_to root_path
    assert_predicate courses(:ai1101).reload, :published?
    assert_empty AuditEvent.all
  end
end
