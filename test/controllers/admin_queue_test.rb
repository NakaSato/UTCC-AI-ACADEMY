require "test_helper"

class AdminQueueTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the queue is truthful when no requests exist" do
    get admin_url(tab: :queue)

    assert_response :success
    assert_includes response.body, I18n.t("admin.queue.empty")
    assert_select "main", text: /TA role request/, count: 0
  end

  test "an admin creates a course transition request from the Courses tab" do
    patch admin_course_state_url(courses(:ai1101)), params: { state: "archived", from: "published" }

    assert_redirected_to admin_path(tab: :queue)
    assert_predicate ApprovalRequest.sole, :pending?
    assert_predicate courses(:ai1101).reload, :published?

    get admin_url(tab: :queue)
    assert_select "[data-approval-request-id=?]", ApprovalRequest.sole.id
    assert_select "form[action=?]", admin_approval_decision_path(ApprovalRequest.sole), count: 0
  end

  test "another admin can approve and the queue records the decision" do
    request = ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                                       from_state: "published", to_state: "archived")
    sign_in_as users(:admin_two)

    post admin_approval_decision_url(request), params: { outcome: "approved" }

    assert_redirected_to admin_path(tab: :queue)
    assert_predicate courses(:ai1101).reload, :archived?
    assert_predicate request.reload, :approved?
    assert_equal "approval_decided", AuditEvent.sole.action
  end

  test "the requester cannot approve their own request" do
    request = ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                                       from_state: "published", to_state: "archived")

    post admin_approval_decision_url(request), params: { outcome: "approved" }

    assert_redirected_to admin_path(tab: :queue)
    assert_equal I18n.t("flash.approval_invalid"), flash[:alert]
    assert_predicate request.reload, :pending?
    assert_predicate courses(:ai1101).reload, :published?
  end

  test "a non-admin cannot access approval decisions" do
    request = ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                                       from_state: "published", to_state: "archived")
    sign_in_as users(:student)

    post admin_approval_decision_url(request), params: { outcome: "approved" }

    assert_redirected_to root_path
    assert_predicate request.reload, :pending?
    assert_empty ApprovalDecision.all
  end
end
