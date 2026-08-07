require "test_helper"

class Recruitment::ReportingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Reporting Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    sign_in_as users(:two)
  end

  test "recruiter sees organization-scoped aggregate reporting" do
    get reporting_recruitment_organization_path(@organization)

    assert_response :success
    assert_select "h1", text: I18n.t("recruitment.reporting.title")
    assert_select "body", /#{I18n.t("recruitment.reporting.suppressed")}/
  end

  test "mentor and unrelated users cannot access reporting" do
    sign_out
    sign_in_as users(:student)
    get reporting_recruitment_organization_path(@organization)
    assert_response :not_found

    sign_out
    sign_in_as users(:instructor)
    get reporting_recruitment_organization_path(@organization)
    assert_response :not_found
  end
end
