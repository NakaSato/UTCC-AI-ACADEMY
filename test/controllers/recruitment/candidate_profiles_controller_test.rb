require "test_helper"

class Recruitment::CandidateProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "student creates and updates a private candidate profile" do
    assert_difference "CandidateProfile.count", 1 do
      patch recruitment_candidate_profile_path, params: {
        candidate_profile: {
          headline: "AI learner",
          summary: "Building a foundation in applied AI.",
          preferred_location: "Bangkok",
          visibility: "private"
        }
      }
    end

    assert_redirected_to edit_recruitment_candidate_profile_path
    profile = users(:one).reload.candidate_profile
    assert_equal "AI learner", profile.headline
    assert_equal "private", profile.visibility
  end

  test "student saves portable fields, consent, and provenance-aware facts" do
    patch recruitment_candidate_profile_path, params: {
      candidate_profile: {
        headline: "AI learner", summary: "Building applied AI projects.", preferred_location: "Bangkok",
        portfolio_url: "https://example.com/portfolio", github_url: "https://github.com/student",
        linkedin_url: "https://linkedin.com/in/student", salary_expectation_min: 25000,
        salary_expectation_max: 40000, salary_currency: "THB", visibility: "searchable",
        application_data_reuse_consent: "1",
        facts_attributes: {
          "0" => { kind: "education", title: "AI Fundamentals", organization: "UTCC", detail: "2026" },
          "1" => { kind: "skill", title: "Ruby", organization: "", detail: "Rails projects" }
        }
      }
    }

    assert_redirected_to edit_recruitment_candidate_profile_path
    profile = users(:one).reload.candidate_profile
    assert_equal "searchable", profile.visibility
    assert_predicate profile, :application_data_reuse_consent?
    assert_equal %w[ education skill ], profile.facts.ordered.pluck(:kind)
    assert_equal "self_reported", profile.facts.first.source
  end

  test "student can export profile metadata and provenance" do
    profile = users(:one).create_candidate_profile!(headline: "Portable")
    profile.facts.create!(kind: "language", title: "Thai", detail: "Native")

    get recruitment_candidate_profile_export_path

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "self_reported"
    assert_includes response.body, "Portable"
  end

  test "student can upload and remove a resume" do
    file = Tempfile.new([ "resume", ".pdf" ])
    file.write("%PDF-1.4 candidate resume")
    file.rewind

    patch recruitment_candidate_profile_path, params: {
      candidate_profile: {
        resume: Rack::Test::UploadedFile.new(file.path, "application/pdf", original_filename: "resume.pdf")
      }
    }
    assert_predicate users(:one).reload.candidate_profile.resume, :attached?

    patch recruitment_candidate_profile_path, params: { candidate_profile: { remove_resume: "1" } }

    assert_not_predicate users(:one).reload.candidate_profile.resume, :attached?
  ensure
    file&.close
    file&.unlink
  end

  test "student can delete profile data" do
    profile = users(:one).create_candidate_profile!(headline: "Delete me")
    profile.facts.create!(kind: "skill", title: "Ruby")

    assert_difference "CandidateProfile.count", -1 do
      delete recruitment_candidate_profile_data_path
    end

    assert_redirected_to root_path
    assert_nil users(:one).reload.candidate_profile
    assert_equal 0, CandidateProfileFact.where(candidate_profile_id: profile.id).count
  end

  test "invalid profile data is not saved" do
    patch recruitment_candidate_profile_path, params: {
      candidate_profile: { github_url: "not-a-url", salary_expectation_min: 100, salary_expectation_max: 50 }
    }

    assert_response :unprocessable_entity
    assert_nil users(:one).reload.candidate_profile
  end

  test "another user cannot read a candidate profile through the self-service route" do
    users(:one).create_candidate_profile!(headline: "Private")

    sign_out
    sign_in_as users(:two)

    get edit_recruitment_candidate_profile_path

    assert_response :success
    assert_not_includes response.body, "Private"
    assert_nil users(:two).candidate_profile
  end

  test "staff cannot use the student candidate profile screen" do
    sign_out
    sign_in_as users(:instructor)

    get edit_recruitment_candidate_profile_path

    assert_redirected_to root_path
  end
end
