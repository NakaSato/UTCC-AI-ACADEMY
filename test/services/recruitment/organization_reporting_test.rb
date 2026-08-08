require "test_helper"

class Recruitment::OrganizationReportingTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Reporting Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    @job = @organization.job_posts.create!(creator: users(:two), title: "Reporting Job", summary: "Summary",
                                           description: "Description", category: "Product", department: "Academy",
                                           team: "Platform", seniority: "Junior", location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
  end

  test "suppresses small application populations and contains no candidate data" do
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Private statement")

    summary = Recruitment::OrganizationReporting.call(organization: @organization, viewer: users(:two))

    assert summary.application_total_suppressed
    assert_nil summary.application_total
    assert summary.application_statuses.all?(&:suppressed)
    assert_equal 1, summary.job_statuses.find { |cell| cell.status == "published" }.count
    I18n.with_locale(:en) do
      summary = Recruitment::OrganizationReporting.call(organization: @organization, viewer: users(:two))

      assert_match "descriptive workflow counts", summary.uncertainty
      assert_equal I18n.t("recruitment.reporting.source_label"), summary.source_label
      assert_equal I18n.t("recruitment.reporting.uncertainty", minimum: 5), summary.uncertainty
    end
  end

  test "shows exact application cells after the minimum reporting population" do
    5.times do |index|
      candidate = User.create!(name: "Report Candidate #{index}", student_id: "201107174#{index.to_s.rjust(4, "0")}",
                               password: "SafePassword#{index}1")
      CandidateProfile.create!(user: candidate, application_data_reuse_consent: true)
      Recruitment::JobApplication.submit!(job_post: @job, candidate:, statement: "Statement #{index}")
    end

    summary = Recruitment::OrganizationReporting.call(organization: @organization, viewer: users(:two))
    submitted = summary.application_statuses.find { |cell| cell.status == "submitted" }

    assert_not summary.application_total_suppressed
    assert_equal 5, summary.application_total
    assert_equal 5, submitted.count
    assert_not submitted.suppressed
  end

  test "only an authorized hiring-team member can receive the report" do
    assert_nil Recruitment::OrganizationReporting.call(organization: @organization, viewer: users(:student))
    assert_nil Recruitment::OrganizationReporting.call(organization: @organization, viewer: users(:instructor))
  end

  test "does not trust a stale active organization object" do
    stale_organization = Organization.find(@organization.id)
    Organization.where(id: @organization.id).update_all(status: "suspended")

    assert_nil Recruitment::OrganizationReporting.call(organization: stale_organization, viewer: users(:two))
  end
end
