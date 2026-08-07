require "test_helper"

class Recruitment::JobMatchPreviewControllerTest < ActionDispatch::IntegrationTest
  setup do
    organization = Organization.create!(name: "Match Controller Org", creator: users(:admin))
    organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = organization.job_posts.create!(
      creator: users(:two), title: "Candidate Match Role", summary: "A role for Ruby learners.", description: "Build tools.",
      category: "Product", department: "Innovation", team: "Academy", seniority: "Junior",
      employment_type: "full_time", location: "Bangkok", remote_policy: "hybrid"
    )
    @job.transition_to!("review")
    @job.transition_to!("published")
  end

  test "student sees factor explanations on a public job" do
    users(:one).create_candidate_profile!.facts.create!(kind: "skill", title: "Ruby")
    sign_in_as users(:one)

    get recruitment_job_path(@job)

    assert_response :success
    assert_select "h2", text: I18n.t("recruitment.jobs.match_preview_title")
    assert_select "article", text: /#{Regexp.escape(I18n.t("recruitment.jobs.match_factors.skill_fit"))}/
    assert_select "body", text: /not a hiring score/
  end

  test "staff can view the job but never receives candidate match data" do
    sign_in_as users(:instructor)

    get recruitment_job_path(@job)

    assert_response :success
    assert_select "h2", text: I18n.t("recruitment.jobs.match_preview_title"), count: 0
  end
end
