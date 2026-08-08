require "test_helper"

class Recruitment::CandidateApplicationAssistantTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Candidate Assistant Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(creator: users(:two), title: "Candidate Test Job", summary: "Summary",
                                           description: "Description", category: "Product", department: "Academy",
                                           team: "Platform", seniority: "Junior", location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    @application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")
  end

  test "returns private submitted-stage preparation guidance to the candidate" do
    guidance = Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: users(:student))

    assert_equal %w[ review_submitted_materials wait_for_review ], guidance.items.map(&:key)
    assert_equal [ "application.statement", "application.status" ], guidance.items.map(&:source)
    assert_match "does not assess your qualifications", guidance.uncertainty
  end

  test "changes the checklist for interview and terminal stages" do
    @application.transition_to!("screening", actor: users(:two))
    @application.transition_to!("interview", actor: users(:two))
    guidance = Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: users(:student))
    assert_includes guidance.items.map(&:key), "prepare_interview_questions"

    @application.transition_to!("rejected", actor: users(:two))
    guidance = Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: users(:student))
    assert_equal [ "record_outcome" ], guidance.items.map(&:key)
  end

  test "never returns guidance to a recruiter or another candidate" do
    assert_nil Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: users(:two))
    assert_nil Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: users(:one))
  end

  test "never returns guidance for an anonymous viewer or an unsaved application" do
    assert_nil Recruitment::CandidateApplicationAssistant.call(application: @application, viewer: nil)

    unsaved_application = Recruitment::JobApplication.new(status: "submitted")
    assert_nil Recruitment::CandidateApplicationAssistant.call(application: unsaved_application, viewer: nil)
  end
end
