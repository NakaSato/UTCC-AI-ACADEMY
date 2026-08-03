require "test_helper"

class ApprovalRequestTest < ActiveSupport::TestCase
  test "a course lifecycle request captures the current state and target" do
    request = ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                                       from_state: "published", to_state: "archived")

    assert_equal ApprovalRequest::COURSE_LIFECYCLE_TRANSITION, request.kind
    assert_equal "published", request.from_state
    assert_equal "archived", request.to_state
    assert_predicate request, :pending?
  end

  test "a second pending request for the same course transition is rejected" do
    ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                             from_state: "published", to_state: "archived")

    duplicate = ApprovalRequest.new(course: courses(:ai1101), requester: users(:admin),
                                    kind: ApprovalRequest::COURSE_LIFECYCLE_TRANSITION,
                                    from_state: "published", to_state: "archived")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:course], :present?
  end

  test "a stale course form cannot create a request" do
    request = ApprovalRequest.new(course: courses(:ai1101), requester: users(:admin),
                                  kind: ApprovalRequest::COURSE_LIFECYCLE_TRANSITION,
                                  from_state: "draft", to_state: "published")

    assert_not request.valid?
    assert_predicate request.errors[:to_state], :present?
  end

  test "only an admin can request a course lifecycle change" do
    request = ApprovalRequest.new(course: courses(:ai1101), requester: users(:student),
                                  kind: ApprovalRequest::COURSE_LIFECYCLE_TRANSITION,
                                  from_state: "published", to_state: "archived")

    assert_not request.valid?
    assert_predicate request.errors[:requester], :present?
  end
end
