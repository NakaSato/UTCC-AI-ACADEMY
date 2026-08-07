require "test_helper"

class Recruitment::CandidateResumeAnalysisTest < ActiveSupport::TestCase
  setup do
    @profile = users(:one).create_candidate_profile!
    @profile.resume.attach(io: StringIO.new("Skills: Ruby, Rails\nExperience: Product intern\n"),
                           filename: "resume.txt", content_type: "text/plain")
  end

  test "rules preview extracts bounded text sections with evidence" do
    analysis = Recruitment::CandidateResumeAnalysisGenerator.call(candidate_profile: @profile, requested_by: users(:one))

    assert_equal "rules_preview", analysis.provider
    assert_equal %w[ skill skill experience strength uncertainty ], analysis.findings.ordered.pluck(:kind)
    skill = analysis.findings.find_by!(title: "Ruby")
    assert_equal "resume_text", skill.source_type
    assert_not skill.inferred?
    assert_equal "Skills: Ruby, Rails", skill.evidence
    assert_in_delta 0.75, skill.confidence.to_f, 0.001
    assert_includes analysis.uncertainty, "not a hiring judgment"
  end

  test "only the profile owner can request and review an analysis" do
    analysis = Recruitment::CandidateResumeAnalysisGenerator.call(candidate_profile: @profile, requested_by: users(:one))
    finding = analysis.findings.find_by!(title: "Ruby")

    assert_raises(ActiveRecord::RecordInvalid) { finding.accept!(reviewer: users(:two)) }
    assert_raises(ActiveRecord::RecordInvalid) do
      Recruitment::CandidateResumeAnalysisGenerator.call(candidate_profile: @profile, requested_by: users(:two))
    end
  end

  test "applying accepted fact findings creates provenance-aware facts and skips signals" do
    analysis = Recruitment::CandidateResumeAnalysisGenerator.call(candidate_profile: @profile, requested_by: users(:one))
    analysis.findings.find_by!(title: "Ruby").accept!(reviewer: users(:one))
    analysis.findings.find_by!(title: "Product intern").accept!(reviewer: users(:one))
    analysis.findings.find_by!(kind: "strength").accept!(reviewer: users(:one))

    analysis.apply!(reviewer: users(:one))

    assert_equal "applied", analysis.reload.status
    assert_equal %w[ skill experience ], @profile.reload.facts.ordered.pluck(:kind)
    assert @profile.facts.all? { |fact| fact.source == "document_extracted" }
    assert_raises(ActiveRecord::RecordInvalid) { analysis.apply!(reviewer: users(:one)) }
  end

  test "binary resume preview records metadata without reading document text" do
    @profile.reload.resume.purge
    @profile.resume.attach(io: StringIO.new("%PDF-1.4 not parsed"), filename: "resume.pdf", content_type: "application/pdf")

    analysis = Recruitment::CandidateResumeAnalysisGenerator.call(candidate_profile: @profile, requested_by: users(:one))

    assert_equal false, analysis.source_context.fetch("text_extracted")
    assert_equal "resume_metadata", analysis.findings.find_by!(kind: "ats_signal").source_type
    assert_includes analysis.findings.find_by!(kind: "skill_gap").detail, "manually"
  end
end
