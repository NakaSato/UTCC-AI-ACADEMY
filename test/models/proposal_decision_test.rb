require "test_helper"

# SPEC-0050. The intake shipped with four statuses and a code path to one of
# them, and SPEC-0049 recorded that as a defect it could not usefully assert
# against: a test that the three dead statuses stay dead would have to be
# deleted by the change that revives them. This is that change, so the
# assertion it could not write — every status the constraint allows is
# reachable, and no other status is — is the last test in this file.
class ProposalDecisionTest < ActiveSupport::TestCase
  def proposal(status: "submitted")
    ProposalRequest.create!(
      user: users(:one), status:,
      title: "Weekly project clinic",
      category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )
  end

  test "an administrator moves a submitted proposal into review and the record says why" do
    request = proposal

    request.decide!(actor: users(:admin), to_status: "in_review", reason: "Reading it this week.")

    assert_equal "in_review", request.reload.status
    decision = request.latest_decision
    assert_equal "in_review", decision.to_status
    assert_equal users(:admin), decision.actor
    assert_equal "Reading it this week.", decision.reason
  end

  test "a second decision joins the first rather than replacing it" do
    request = proposal
    request.decide!(actor: users(:admin), to_status: "in_review", reason: "Reading it this week.")
    request.decide!(actor: users(:admin_two), to_status: "planned", reason: "Scheduled for the next increment.")

    assert_equal "planned", request.reload.status
    assert_equal %w[ in_review planned ], request.decisions.oldest_first.map(&:to_status)
    assert_equal "Scheduled for the next increment.", request.latest_decision.reason
  end

  test "an answered proposal is not answered twice" do
    %w[ planned declined ].each do |terminal|
      request = proposal(status: terminal)

      assert_predicate request, :decided?
      assert_raises(ActiveRecord::RecordInvalid) do
        request.decide!(actor: users(:admin), to_status: "in_review", reason: "Reopening it.")
      end
      assert_equal terminal, request.reload.status
      assert_empty request.decisions
    end
  end

  # `submitted` is what the intake writes. Nothing decides a proposal into it,
  # because "undecided again" is not something an author can be told.
  test "a proposal is never decided back into the queue it came from" do
    request = proposal(status: "in_review")

    assert_raises(ActiveRecord::RecordInvalid) do
      request.decide!(actor: users(:admin), to_status: "submitted", reason: "Back to the queue.")
    end
    assert_equal "in_review", request.reload.status
  end

  test "only an administrator decides" do
    [ users(:one), users(:instructor) ].each do |actor|
      request = proposal

      assert_not request.decidable_by?(actor)
      assert_raises(ActiveRecord::RecordInvalid) do
        request.decide!(actor:, to_status: "declined", reason: "Not this term.")
      end
      assert_equal "submitted", request.reload.status
      assert_empty request.decisions
    end
  end

  test "a decision without a reason changes nothing" do
    request = proposal

    [ nil, "", "   " ].each do |blank|
      assert_raises(ActiveRecord::RecordInvalid) do
        request.decide!(actor: users(:admin), to_status: "declined", reason: blank)
      end
    end

    assert_equal "submitted", request.reload.status
    assert_empty request.decisions
  end

  test "the reason is normalized and bounded" do
    request = proposal
    request.decide!(actor: users(:admin), to_status: "planned", reason: "  Scheduled.  ")

    assert_equal "Scheduled.", request.latest_decision.reason

    over_long = ProposalDecision.new(proposal_request: request, actor: users(:admin),
                                     to_status: "declined", reason: "x" * 1_001)
    assert_not_predicate over_long, :valid?
  end

  # The author was told this. Neither half of the record may move afterwards.
  test "a written decision cannot be edited or deleted" do
    request = proposal
    request.decide!(actor: users(:admin), to_status: "declined", reason: "Out of scope for now.")
    decision = request.latest_decision

    assert_not decision.update(reason: "Something else")
    assert_not decision.destroy
    assert_equal "Out of scope for now.", decision.reload.reason
  end

  test "a refused decision leaves no half-written state behind" do
    request = proposal
    before = ProposalDecision.count

    assert_raises(ActiveRecord::RecordInvalid) do
      request.decide!(actor: users(:admin), to_status: "planned", reason: "")
    end

    assert_equal before, ProposalDecision.count
    assert_equal "submitted", request.reload.status
  end

  # The assertion SPEC-0049 said could not be written until ADR-0049 decision 6
  # was settled. Both halves matter: a status the constraint allows and the code
  # cannot reach is a status an author may be shown and never given, and a
  # status the code can reach and the constraint forbids is a 500.
  test "every status the constraint allows is reachable, and no other status is" do
    allowed = ProposalRequest::STATUSES
    reachable = (ProposalRequest::TRANSITIONS.values.flatten + [ "submitted" ]).uniq

    assert_equal allowed.sort, reachable.sort,
                 "the vocabulary and the paths that reach it have drifted apart"
    assert_equal allowed.sort, (ProposalDecision::OUTCOMES + [ "submitted" ]).sort,
                 "a decision outcome exists that the proposal vocabulary does not carry"

    # Reached for real, one status at a time, rather than only in the constants.
    reached = [ "submitted" ]
    request = proposal
    request.decide!(actor: users(:admin), to_status: "in_review", reason: "Reading it.")
    reached << request.reload.status
    request.decide!(actor: users(:admin), to_status: "planned", reason: "Scheduled.")
    reached << request.reload.status
    declined = proposal
    declined.decide!(actor: users(:admin), to_status: "declined", reason: "Not this term.")
    reached << declined.reload.status

    assert_equal allowed.sort, reached.sort
  end

  test "the database refuses a status the model never produces" do
    request = proposal

    assert_raises(ActiveRecord::StatementInvalid) do
      ProposalDecision.insert!({ proposal_request_id: request.id, actor_id: users(:admin).id,
                                 to_status: "submitted", reason: "Bypassing the model.",
                                 created_at: Time.current, updated_at: Time.current })
    end
  end
end
