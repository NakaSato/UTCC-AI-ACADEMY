require "test_helper"

# Four populations share one Rails app and used to share one navigation, so a
# recruiter browsed the recruitment screens under a header advertising lessons,
# a knowledge map and a heart counter. The chrome and the front door now both
# ask User#workspace.
class WorkspaceNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Console Co", creator: users(:admin))
    @company = users(:console_company)
    @organization.memberships.create!(user: @company, role: "recruiter")
  end

  # css_select takes no `?` substitution, so the label goes in by hand.
  def nav_labels
    css_select(%(nav[aria-label="#{I18n.t("chrome.nav_label")}"] a)).map { it.text.strip }
  end

  # ---- The front door -------------------------------------------------------

  test "each workspace has its own home" do
    {
      users(:student) => nil,
      users(:instructor) => instructor_path,
      users(:admin) => admin_path,
      # One organization, so the front door is that company's own page.
      @company => company_path(@organization)
    }.each do |user, destination|
      sign_in_as user
      get root_url

      if destination
        assert_redirected_to destination, "#{user.workspace} should land on #{destination}"
      else
        assert_response :success
        assert_select "h1", text: I18n.t("catalog.title")
      end
      sign_out
    end
  end

  # ---- The navigation -------------------------------------------------------

  test "a student keeps the learning nav" do
    sign_in_as users(:one)
    get root_url

    assert_includes nav_labels, I18n.t("chrome.nav.catalog")
    assert_includes nav_labels, I18n.t("chrome.nav.map")
    assert_not_includes nav_labels, I18n.t("chrome.nav.instructor")
    assert_not_includes nav_labels, I18n.t("chrome.nav.organizations")
  end

  test "an instructor gets the teaching nav and none of the coursework" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_equal [ I18n.t("chrome.nav.instructor"), I18n.t("chrome.nav.writing") ], nav_labels
  end

  test "an admin gets the admin nav, including organizations" do
    sign_in_as users(:admin)
    get admin_url

    assert_equal [ I18n.t("chrome.nav.admin"), I18n.t("chrome.nav.instructor"),
                   I18n.t("chrome.nav.organizations") ], nav_labels
  end

  # The one this whole change is about: a company member holds the student role,
  # so asking the role handed them a learner's app.
  test "a company member gets the company nav and no coursework" do
    sign_in_as @company
    get companies_url

    assert_equal [ I18n.t("chrome.nav.organizations"), I18n.t("chrome.nav.business_cases"),
                   I18n.t("chrome.nav.placements") ], nav_labels
    assert_not_includes nav_labels, I18n.t("chrome.nav.catalog")
    assert_not_includes nav_labels, I18n.t("chrome.nav.lesson")
  end

  # Both navs read the same list, so the drawer must not disagree with the rail.
  test "the burger drawer carries the same list as the rail" do
    sign_in_as @company
    get companies_url

    drawer = css_select("[data-menu=nav] a").map { it.text.strip }
    assert_equal nav_labels, drawer
  end

  # ---- The gamification strip ----------------------------------------------

  test "a company member is left out of the hearts mechanic" do
    sign_in_as @company
    get companies_url

    assert_not_includes response.body, I18n.t("chrome.hearts_left", count: 5, max: 5)
  end

  # The strip is a term and a section. A recruiter has neither, and an empty
  # bar announcing somebody else's semester is worse than no bar.
  test "a company member does not get the academic strip at all" do
    sign_in_as @company
    get companies_url

    assert_select "header [data-strip=academy]", false
  end

  test "an instructor keeps the semester context" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_includes response.body, I18n.t("chrome.semester")
    assert_select "header [data-strip=academy]", 1
  end

  # A revoked membership drops them back to being an ordinary learner, chrome
  # and all — the same rule that closes /console.
  test "revoking the membership returns them to the learning app" do
    @organization.memberships.find_by!(user: @company).update!(status: "revoked")

    sign_in_as @company
    get root_url

    assert_response :success
    assert_includes nav_labels, I18n.t("chrome.nav.catalog")
  end
end
