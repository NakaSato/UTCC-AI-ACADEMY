require "test_helper"

class Recruitment::JobDiscoveryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Discovery Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(
      creator: users(:two), title: "Ruby Discovery Role", summary: "Use Ruby with the academy team.",
      description: "Build useful learning tools.", category: "Product", department: "Innovation",
      team: "Academy", seniority: "Junior", employment_type: "full_time", location: "Bangkok",
      remote_policy: "hybrid"
    )
    @job.transition_to!("review")
    @job.transition_to!("published")
    users(:one).create_candidate_profile!.facts.create!(kind: "skill", title: "Ruby")
    sign_in_as users(:one)
  end

  test "student can search, save, and remove a published job" do
    get recruitment_jobs_path, params: { query: "ruby" }
    assert_response :success
    assert_select "h2", text: /Ruby Discovery Role/

    assert_difference "Recruitment::SavedJob.count", 1 do
      post recruitment_save_job_path(@job)
    end
    assert_redirected_to recruitment_jobs_path

    assert_difference "Recruitment::SavedJob.count", -1 do
      delete recruitment_unsave_job_path(@job)
    end
  end

  test "student can dismiss and restore a recommendation" do
    assert_difference "Recruitment::JobDiscoveryDismissal.count", 1 do
      post recruitment_dismiss_job_recommendation_path(@job)
    end
    assert_redirected_to recruitment_jobs_path

    assert_difference "Recruitment::JobDiscoveryDismissal.count", -1 do
      delete recruitment_undismiss_job_recommendation_path(@job)
    end
  end

  # The undo existed from the start with nothing linking to it, so dismissing a
  # recommendation was one-way for anyone who did not know the route.
  test "a dismissed recommendation is listed with a way to bring it back" do
    post recruitment_dismiss_job_recommendation_path(@job)

    get recruitment_jobs_path

    assert_response :success
    assert_select "h2", I18n.t("recruitment.jobs.dismissed_title")
    assert_select "form[action=?]", recruitment_undismiss_job_recommendation_path(@job)
  end

  test "a student who has dismissed nothing sees no dismissed section" do
    get recruitment_jobs_path

    assert_response :success
    assert_select "h2", { text: I18n.t("recruitment.jobs.dismissed_title"), count: 0 }
  end

  test "duplicate save and dismiss requests are idempotent" do
    post recruitment_save_job_path(@job)
    assert_no_difference [ "Recruitment::SavedJob.count", "AuditEvent.count" ] do
      post recruitment_save_job_path(@job)
    end

    post recruitment_dismiss_job_recommendation_path(@job)
    assert_no_difference [ "Recruitment::JobDiscoveryDismissal.count", "AuditEvent.count" ] do
      post recruitment_dismiss_job_recommendation_path(@job)
    end
  end

  test "alerts require consent and are rate limited on discovery visits" do
    patch recruitment_job_discovery_preferences_path, params: {
      recruitment_job_discovery_preference: {
        alert_consent: "1", alerts_enabled: "1", alert_frequency: "daily", search_query: "Ruby"
      }
    }
    assert_redirected_to edit_recruitment_job_discovery_preferences_path

    assert_difference "Notification.count", 1 do
      get recruitment_jobs_path
    end
    assert_equal "recruitment_job_alert", users(:one).notifications.order(:id).last.kind

    assert_no_difference "Notification.count" do
      get recruitment_jobs_path
    end
  end

  test "another student cannot mutate this student's discovery state" do
    sign_out
    sign_in_as users(:student)

    post recruitment_save_job_path(@job)

    assert_response :redirect
    assert_equal 0, Recruitment::SavedJob.where(user: users(:one), job_post: @job).count
    assert_equal 1, Recruitment::SavedJob.where(user: users(:student), job_post: @job).count
  end

  test "staff cannot use candidate discovery controls" do
    sign_out
    sign_in_as users(:instructor)

    post recruitment_save_job_path(@job)

    assert_redirected_to root_path
  end
end
