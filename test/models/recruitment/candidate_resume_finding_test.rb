require "test_helper"

class Recruitment::CandidateResumeFindingTest < ActiveSupport::TestCase
  test "editing preserves evidence and requires a reviewable finding" do
    profile = users(:one).create_candidate_profile!
    analysis = profile.resume_analyses.create!(
      requested_by: users(:one), provider: "rules_preview", source_label: "Source", uncertainty: "Uncertain"
    )
    finding = analysis.findings.create!(kind: "skill", title: "Ruby", detail: "Old", evidence: "Skills: Ruby",
                                       source_type: "resume_text", confidence: 0.75, position: 0)

    finding.edit!({ title: "Ruby on Rails", detail: "Corrected" }, reviewer: users(:one))

    assert_equal "edited", finding.status
    assert_equal "Ruby on Rails", finding.title
    assert_equal "Skills: Ruby", finding.evidence
    assert_equal "reviewed", analysis.reload.status
  end

  test "rejects unsupported kinds and source types" do
    profile = users(:one).create_candidate_profile!
    analysis = profile.resume_analyses.create!(
      requested_by: users(:one), provider: "rules_preview", source_label: "Source", uncertainty: "Uncertain"
    )
    finding = analysis.findings.new(kind: "gender", title: "Unknown", evidence: "Unknown", source_type: "resume_text",
                                    confidence: 0.5)

    assert_not finding.valid?
    assert_predicate finding.errors[:kind], :any?
  end
end
