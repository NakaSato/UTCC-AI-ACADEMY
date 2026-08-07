require "test_helper"

class Recruitment::CandidateResumeAnalysesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @profile = users(:one).create_candidate_profile!
    @profile.resume.attach(io: StringIO.new("Skills: Ruby, Rails\nExperience: Product intern\n"),
                           filename: "resume.txt", content_type: "text/plain")
    sign_in_as users(:one)
  end

  test "student can generate, correct, accept, and apply resume findings" do
    assert_difference "Recruitment::CandidateResumeAnalysis.count", 1 do
      post recruitment_candidate_profile_resume_analysis_path
    end
    analysis = @profile.reload.resume_analyses.last
    finding = analysis.findings.find_by!(title: "Ruby")
    assert_redirected_to edit_recruitment_candidate_profile_path

    patch recruitment_candidate_resume_analysis_finding_path(analysis, finding), params: {
      recruitment_candidate_resume_finding: { title: "Ruby on Rails", detail: "Corrected by candidate" }
    }
    assert_equal "edited", finding.reload.status

    post recruitment_accept_candidate_resume_analysis_finding_path(analysis, finding)
    assert_equal "accepted", finding.reload.status
    post recruitment_apply_candidate_resume_analysis_path(analysis)

    assert_redirected_to edit_recruitment_candidate_profile_path
    assert_equal "applied", analysis.reload.status
    assert_equal "Ruby on Rails", @profile.reload.facts.find_by!(source: "document_extracted").title
  end

  test "another student cannot read or mutate the analysis" do
    post recruitment_candidate_profile_resume_analysis_path
    analysis = @profile.reload.resume_analyses.last
    finding = analysis.findings.first

    sign_out
    sign_in_as users(:two)
    patch recruitment_candidate_resume_analysis_finding_path(analysis, finding), params: {
      recruitment_candidate_resume_finding: { title: "Stolen", detail: "No" }
    }

    assert_response :not_found
    assert_equal "pending", finding.reload.status
  end

  test "student cannot analyze without a resume" do
    @profile.reload.resume.purge

    assert_no_difference "Recruitment::CandidateResumeAnalysis.count" do
      post recruitment_candidate_profile_resume_analysis_path
    end

    assert_redirected_to edit_recruitment_candidate_profile_path
  end
end
