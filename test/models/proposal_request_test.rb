require "test_helper"

class ProposalRequestTest < ActiveSupport::TestCase
  test "accepts a complete proposal from a learner" do
    proposal = ProposalRequest.new(
      user: users(:one),
      title: "Weekly project clinic",
      category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )

    assert_predicate proposal, :valid?
  end

  test "rejects staff accounts that are not contributors" do
    proposal = ProposalRequest.new(
      user: users(:admin),
      title: "Admin proposal",
      category: "feature",
      problem: "A problem",
      idea: "An idea",
      impact: "An impact"
    )

    assert_not_predicate proposal, :valid?
    assert_predicate proposal.errors[:user], :present?
  end

  test "normalizes copy and rejects invalid categories" do
    proposal = ProposalRequest.new(
      user: users(:one),
      title: "  A useful idea  ",
      category: "unknown",
      problem: "  A problem  ",
      idea: "  An idea  ",
      impact: "  An impact  "
    )

    assert_not_predicate proposal, :valid?
    assert_equal "A useful idea", proposal.title
    assert_equal "A problem", proposal.problem
    assert_equal "An idea", proposal.idea
    assert_equal "An impact", proposal.impact
    assert_predicate proposal.errors[:category], :present?
  end

  test "formats a stable reference after persistence" do
    proposal = ProposalRequest.create!(
      user: users(:one),
      title: "Reference test",
      category: "platform",
      problem: "A problem",
      idea: "An idea",
      impact: "An impact"
    )

    assert_match(/^PR-\d{4}$/, proposal.reference)
  end
end
