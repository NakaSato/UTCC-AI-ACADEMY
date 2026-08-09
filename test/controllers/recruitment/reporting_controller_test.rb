require "test_helper"

class Recruitment::ReportingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Reporting Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    sign_in_as users(:two)
  end

  test "recruiter sees organization-scoped aggregate reporting" do
    get reporting_company_path(@organization)

    assert_response :success
    assert_select "h1", text: I18n.t("recruitment.reporting.title")
    assert_select "body", /#{I18n.t("recruitment.reporting.suppressed")}/
  end

  test "reporting does not expose candidate identity or application text" do
    job = @organization.job_posts.create!(creator: users(:two), title: "Reporting Job", summary: "Summary",
                                           description: "Description", category: "Product", department: "Academy",
                                           team: "Platform", seniority: "Junior", location: "Bangkok")
    job.transition_to!("review")
    job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    Recruitment::JobApplication.submit!(job_post: job, candidate: users(:student), statement: "Candidate secret statement")

    get reporting_company_path(@organization)

    assert_response :success
    assert_no_match "Candidate secret statement", response.body
    assert_no_match users(:student).name, response.body
    assert_no_match users(:student).student_id, response.body
  end

  test "mentor and unrelated users cannot access reporting" do
    sign_out
    sign_in_as users(:student)
    get reporting_company_path(@organization)
    assert_response :not_found

    sign_out
    sign_in_as users(:instructor)
    get reporting_company_path(@organization)
    assert_response :not_found
  end

  test "reporting metadata follows the selected locale" do
    get reporting_company_path(@organization, lang: "th")

    assert_response :success
    assert_select "main", /#{Regexp.escape(I18n.t("recruitment.reporting.source_label", locale: :th))}/
    assert_select "main", /#{Regexp.escape(I18n.t("recruitment.reporting.uncertainty", minimum: 5, locale: :th))}/
  end
end
