require "test_helper"

# A company's profile is /company/north-star — the address a company would print
# on a page about itself, under a prefix that says what it is. Everything scoped
# to that company sits under the same prefix.
class CompanyProfileTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "North Star", creator: users(:admin))
    @member = users(:console_company)
    @organization.memberships.create!(user: @member, role: "owner")
  end

  test "a member opens their company at its name" do
    sign_in_as @member
    get "/company/north-star"

    assert_response :success
    assert_select "h1", "North Star"
  end

  test "the helper builds the name, not the row id" do
    assert_equal "/company/north-star", company_path(@organization)
  end

  # The prefix is what keeps company names out of the root namespace, so no
  # reserved-name list is needed and a real path cannot be shadowed.
  test "a real path is not shadowed by a company name" do
    sign_in_as users(:admin)

    { "/admin" => I18n.t("admin.title"), "/map" => nil }.each_key do |path|
      get path
      assert_response :success, "#{path} must not be shadowed by a company"
    end

    sign_out
    get "/login"
    assert_response :success
  end

  test "an unknown name is not found" do
    sign_in_as @member
    get "/company/no-such-company"

    assert_response :not_found
  end

  # Visibility is unchanged by the prettier URL: the profile is for members and
  # admins, and a stranger cannot read it by guessing the name.
  test "a non-member cannot read a company at its name" do
    sign_in_as users(:two)
    get "/company/north-star"

    assert_response :not_found
  end

  test "a signed-out visitor is sent to the front door" do
    sign_out
    get "/company/north-star"

    assert_redirected_to root_path
  end

  # One prefix for everything about a company, so its URLs read as one set
  # rather than a name for the profile and a namespace for everything behind it.
  test "the workspace behind the profile shares the prefix" do
    assert_equal "/company/north-star/job_posts", company_job_posts_path(@organization)
    assert_equal "/company/north-star/internship-requests",
                 company_internship_requests_path(@organization)
    assert_equal "/company", companies_path
  end
end
