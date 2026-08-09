require "test_helper"

# A company's profile is /northstar — the address a company would print on a
# page about itself. The route sits last in the file so every real path wins,
# and Organization::RESERVED_SLUGS makes sure no company is ever named something
# that route could not reach.
class CompanyProfileTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "North Star", creator: users(:admin))
    @member = users(:console_company)
    @organization.memberships.create!(user: @member, role: "owner")
  end

  test "a member opens their company at its name" do
    sign_in_as @member
    get "/north-star"

    assert_response :success
    assert_select "h1", "North Star"
  end

  test "the helper builds the name, not the row id" do
    assert_equal "/north-star", company_path(@organization)
  end

  # The vanity route is last, so a real path must still win however an
  # organization is named — and it cannot be named these anyway.
  test "a reserved path still reaches its own screen" do
    sign_in_as users(:admin)

    { "/admin" => I18n.t("admin.title"), "/map" => nil }.each_key do |path|
      get path
      assert_response :success, "#{path} must not be shadowed by the company route"
    end

    sign_out
    get "/login"
    assert_response :success
  end

  test "an unknown name is not found" do
    sign_in_as @member
    get "/no-such-company"

    assert_response :not_found
  end

  # Visibility is unchanged by the prettier URL: the profile is for members and
  # admins, and a stranger cannot read it by guessing the name.
  test "a non-member cannot read a company at its name" do
    sign_in_as users(:two)
    get "/north-star"

    assert_response :not_found
  end

  test "a signed-out visitor is sent to the front door" do
    sign_out
    get "/north-star"

    assert_redirected_to root_path
  end

  # Nested workspace routes carry the same name, so a company's URLs read as one
  # set rather than a name for the profile and a number for everything behind it.
  test "the workspace behind the profile is addressed by name too" do
    assert_equal "/recruitment/organizations/north-star/job_posts",
                 recruitment_organization_job_posts_path(@organization)
  end
end
