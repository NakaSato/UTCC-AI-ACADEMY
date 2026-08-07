require "test_helper"

class Recruitment::JobApplicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Application Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(creator: users(:two), title: "AI Product Analyst", summary: "Use evidence.",
                                           description: "Work with product and engineering.", category: "Product",
                                           department: "Academy", team: "Platform", seniority: "Junior",
                                           location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    sign_in_as users(:student)
  end

  test "a student submits and sees their current stage and next action" do
    assert_difference [ "Recruitment::JobApplication.count", "Recruitment::JobApplicationEvent.count", "AuditEvent.count" ], 1 do
      post recruitment_apply_job_path(@job), params: {
        recruitment_job_application: { statement: "I want to build useful tools." }
      }
    end

    application = Recruitment::JobApplication.order(:id).last
    assert_redirected_to recruitment_job_application_path(application)
    follow_redirect!
    assert_select "body", /#{I18n.t("recruitment.applications.statuses.submitted")}/
    assert_select "body", /#{I18n.t("recruitment.applications.next_actions.submitted")}/
    assert_select "body", /#{I18n.t("recruitment.applications.candidate_assistant_title")}/
  end

  test "a student cannot apply without consent or to an expired job" do
    users(:student).candidate_profile.update!(application_data_reuse_consent: false)
    assert_no_difference "Recruitment::JobApplication.count" do
      post recruitment_apply_job_path(@job), params: {
        recruitment_job_application: { statement: "No consent" }
      }
    end
    assert_redirected_to recruitment_job_path(@job)

    users(:student).candidate_profile.update!(application_data_reuse_consent: true)
    @job.update!(closes_on: 1.day.ago)
    assert_no_difference "Recruitment::JobApplication.count" do
      post recruitment_apply_job_path(@job), params: {
        recruitment_job_application: { statement: "Too late" }
      }
    end
  end

  test "a recruiter sees only the organization's pipeline and can transition an application" do
    post recruitment_apply_job_path(@job), params: {
      recruitment_job_application: { statement: "Ready" }
    }
    application = Recruitment::JobApplication.order(:id).last

    sign_out
    sign_in_as users(:two)
    get recruitment_organization_job_post_applications_path(@organization, @job)
    assert_response :success
    assert_select "body", /นักศึกษา สาม/

    assert_difference [ "Recruitment::JobApplicationEvent.count", "AuditEvent.count" ], 1 do
      post transition_recruitment_organization_job_post_application_path(@organization, @job, application), params: {
        recruitment_job_application: { status: "screening", note: "Reviewing evidence", lock_version: application.lock_version }
      }
    end
    assert_redirected_to recruitment_organization_job_post_application_path(@organization, @job, application)
    assert_predicate application.reload, :screening?

    get recruitment_organization_job_post_application_path(@organization, @job, application)
    assert_response :success
    assert_select "body", /#{I18n.t("recruitment.applications.assistant_title")}/
  end

  test "an unrelated member cannot read the candidate pipeline" do
    post recruitment_apply_job_path(@job), params: {
      recruitment_job_application: { statement: "Ready" }
    }

    sign_out
    sign_in_as users(:instructor)
    get recruitment_organization_job_post_applications_path(@organization, @job)

    assert_response :not_found
  end

  test "a candidate cannot read another candidate's application" do
    post recruitment_apply_job_path(@job), params: {
      recruitment_job_application: { statement: "Private" }
    }
    application = Recruitment::JobApplication.order(:id).last

    sign_out
    sign_in_as users(:one)
    get recruitment_job_application_path(application)

    assert_response :not_found
  end

  test "a candidate can send an in-app message without changing the application stage" do
    post recruitment_apply_job_path(@job), params: {
      recruitment_job_application: { statement: "Ready" }
    }
    application = Recruitment::JobApplication.order(:id).last

    assert_difference [ "Recruitment::JobApplicationMessage.count", "AuditEvent.count" ], 1 do
      post recruitment_message_job_application_path(application), params: {
        recruitment_job_application_message: { body: "Could you share the next step?" }
      }
    end

    assert_redirected_to recruitment_job_application_path(application)
    assert_predicate application.reload, :submitted?
    follow_redirect!
    assert_select "body", /Could you share the next step\?/
  end

  test "an authorized recruiter can reply in the application conversation" do
    post recruitment_apply_job_path(@job), params: {
      recruitment_job_application: { statement: "Ready" }
    }
    application = Recruitment::JobApplication.order(:id).last

    sign_out
    sign_in_as users(:two)
    assert_difference [ "Recruitment::JobApplicationMessage.count", "AuditEvent.count" ], 1 do
      post message_recruitment_organization_job_post_application_path(@organization, @job, application), params: {
        recruitment_job_application_message: { body: "Please prepare a short portfolio example." }
      }
    end

    assert_redirected_to recruitment_organization_job_post_application_path(@organization, @job, application)
    assert_predicate application.reload, :submitted?
    follow_redirect!
    assert_select "body", /Please prepare a short portfolio example\./
  end
end
