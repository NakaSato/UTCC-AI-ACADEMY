require "test_helper"

class CandidateProfileFactTest < ActiveSupport::TestCase
  setup do
    @profile = CandidateProfile.create!(user: users(:one))
  end

  test "stores a self-reported fact with provenance and confidence" do
    fact = @profile.facts.create!(kind: "skill", title: "Ruby", detail: "Built Rails features")

    assert_equal "self_reported", fact.source
    assert_equal 1.0, fact.confidence.to_f
  end

  test "rejects unknown source and confidence outside the range" do
    fact = @profile.facts.new(kind: "skill", title: "Ruby", source: "guessed", confidence: 1.5)

    assert_not fact.valid?
    assert_predicate fact.errors[:source], :any?
    assert_predicate fact.errors[:confidence], :any?
  end

  test "facts cannot belong to a staff profile" do
    staff_profile = CandidateProfile.new(user: users(:instructor))
    fact = staff_profile.facts.build(kind: "experience", title: "Teaching")

    assert_not fact.valid?
    assert_predicate fact.errors[:candidate_profile], :any?
  end
end
