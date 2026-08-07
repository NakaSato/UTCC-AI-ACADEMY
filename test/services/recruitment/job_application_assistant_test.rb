require "test_helper"

class Recruitment::JobApplicationAssistantTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Assistant Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(creator: users(:two), title: "Assistant Test Job", summary: "Summary",
                                           description: "Description", category: "Product", department: "Academy",
                                           team: "Platform", seniority: "Junior", location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    @application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")
  end

  test "returns a review cue for a fresh submitted application" do
    recommendation = Recruitment::JobApplicationAssistant.call(application: @application, viewer: users(:two),
                                                               reference_time: @application.applied_at + 1.day)

    assert_equal "review_application", recommendation.action
    assert_not recommendation.attention
    assert_equal 7, recommendation.threshold_days
    assert_equal Recruitment::JobApplicationAssistant::UNCERTAINTY, recommendation.uncertainty
  end

  test "marks an overdue stage without changing the application" do
    @application.events.update_all(occurred_at: 8.days.ago)
    recommendation = Recruitment::JobApplicationAssistant.call(application: @application, viewer: users(:two),
                                                               reference_time: Time.current)

    assert_predicate recommendation, :attention
    assert_predicate @application.reload, :submitted?
  end

  test "uses the current workflow stage and closes terminal records" do
    @application.transition_to!("rejected", actor: users(:two))
    recommendation = Recruitment::JobApplicationAssistant.call(application: @application, viewer: users(:two))

    assert_equal "close_record", recommendation.action
    assert_not recommendation.attention
    assert_nil recommendation.threshold_days
  end

  test "does not return recruiter guidance outside the organization boundary" do
    assert_nil Recruitment::JobApplicationAssistant.call(application: @application, viewer: users(:student))
  end
end
