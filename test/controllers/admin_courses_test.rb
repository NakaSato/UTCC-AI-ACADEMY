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

  test "a lifecycle change creates a request and a second admin can approve it" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "archived" }

    assert_redirected_to admin_path(tab: :queue)
    assert_predicate course.reload, :published?
    request = ApprovalRequest.sole
    assert_equal users(:admin), request.requester
    assert_predicate request, :pending?

    sign_in_as users(:admin_two)
    post admin_approval_decision_url(request), params: { outcome: "approved" }

    assert_redirected_to admin_path(tab: :queue)
    assert_predicate course.reload, :archived?
    assert_predicate request.reload, :approved?
    event = AuditEvent.sole
    assert_equal "approval_decided", event.action
    assert_equal users(:admin_two), event.user
    assert_equal({ "request_id" => request.id, "course" => "AI1101", "outcome" => "approved",
                   "from" => "published", "to" => "archived", "reason" => nil }, event.params)
    assert_equal :warn, event.level
  end

  test "an invalid transition changes neither course nor audit log" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "draft" }

    assert_redirected_to admin_path(tab: :courses)
    assert_match(/To state/, flash[:alert])
    assert_predicate course.reload, :published?
    assert_empty ApprovalRequest.all
    assert_empty AuditEvent.all
  end

  test "a stale transition changes neither course nor audit log" do
    course = courses(:ai1101)

    patch admin_course_state_url(course), params: { state: "archived", from: "draft" }

    assert_redirected_to admin_path(tab: :courses)
    assert_predicate course.reload, :published?
    assert flash[:alert].present?
    assert_empty ApprovalRequest.all
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
