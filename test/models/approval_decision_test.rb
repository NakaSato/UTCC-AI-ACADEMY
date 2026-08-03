require "test_helper"

class ApprovalDecisionTest < ActiveSupport::TestCase
  setup do
    @request = ApprovalRequest.create_course_lifecycle!(course: courses(:ai1101), requester: users(:admin),
                                                        from_state: "published", to_state: "archived")
    Current.session = users(:admin_two).sessions.create!
  end

  teardown { Current.reset }

  test "approval changes the course and writes append-only history" do
    @request.decide!(actor: users(:admin_two), outcome: "approved", note: "Reviewed by academic owner")

    assert_predicate courses(:ai1101).reload, :archived?
    assert_predicate @request.reload, :approved?
    decision = ApprovalDecision.sole
    assert_equal users(:admin_two), decision.actor
    assert_equal "approved", decision.outcome
    assert_not decision.update(note: "rewritten")
    assert_not decision.destroy
  end

  test "rejection records the outcome without changing the course" do
    @request.decide!(actor: users(:admin_two), outcome: "rejected")

    assert_predicate courses(:ai1101).reload, :published?
    assert_predicate @request.reload, :rejected?
    assert_equal "rejected", ApprovalDecision.sole.outcome
  end

  test "the requester cannot decide their own request" do
    assert_raises(ActiveRecord::RecordInvalid) do
      @request.decide!(actor: users(:admin), outcome: "approved")
    end

    assert_predicate @request.reload, :pending?
    assert_empty ApprovalDecision.all
  end

  test "a stale request does not create a decision or audit event" do
    courses(:ai1101).update!(lifecycle_state: "archived")

    assert_raises(ActiveRecord::RecordInvalid) do
      @request.decide!(actor: users(:admin_two), outcome: "approved")
    end

    assert_predicate @request.reload, :pending?
    assert_empty ApprovalDecision.all
    assert_empty AuditEvent.all
  end
end
