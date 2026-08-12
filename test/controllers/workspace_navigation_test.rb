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
  # The menubar's panels, one per category. The compact button below `md`
  # renders the same destinations a second time — `nav_compact_labels` reads
  # those, and a test below holds the two to the same list.
  def nav_labels
    css_select("[data-menu=nav] a").map { it.text.strip }
  end

  def nav_compact_labels
    css_select("[data-menu=nav-compact] a").map { it.text.strip }
  end

  # ---- The front door -------------------------------------------------------

  test "each workspace has its own home" do
    {
      users(:student) => nil,
      users(:instructor) => instructor_path,
      users(:admin) => admin_path,
      # One organization, so the front door is that company's work surface —
      # the record is one click away at /company/:slug. ADR-0048.
      @company => work_company_path(@organization)
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

    assert_equal [ I18n.t("chrome.nav.instructor"), I18n.t("chrome.nav.internships"),
                   I18n.t("chrome.nav.writing") ], nav_labels
  end

  # No Teaching entry: /instructor reports on a section an admin does not teach.
  # The route still admits them — this is about what the nav claims is theirs.
  test "an admin gets the admin nav and is not offered the teaching screen" do
    sign_in_as users(:admin)
    get admin_url

    assert_equal [ I18n.t("chrome.nav.admin"), I18n.t("chrome.nav.organizations"),
                   I18n.t("chrome.nav.internships") ], nav_labels

    get instructor_url
    assert_response :success
  end

  # The one this whole change is about: a company member holds the student role,
  # so asking the role handed them a learner's app.
  test "a company member gets the company nav and no coursework" do
    sign_in_as @company
    get companies_url

    assert_equal [ I18n.t("chrome.nav.work"), I18n.t("chrome.nav.organizations"),
                   I18n.t("chrome.nav.business_cases"), I18n.t("chrome.nav.placements") ], nav_labels
    assert_not_includes nav_labels, I18n.t("chrome.nav.catalog")
    assert_not_includes nav_labels, I18n.t("chrome.nav.lesson")
  end

  def nav_categories
    css_select("nav[aria-label] button[data-nav-group]").map { it["data-nav-group"] }
  end

  # The menubar is the categories, and the categories are the whole of the nav:
  # a category cannot quietly add a destination and a destination cannot escape
  # a category.
  test "the menubar is the categories, and every destination sits under one" do
    sign_in_as users(:one)
    get root_url

    assert_equal [ I18n.t("chrome.nav_group.learn"), I18n.t("chrome.nav_group.track"),
                   I18n.t("chrome.nav_group.beyond") ], nav_categories

    grouped = css_select("[data-menu=nav] a").map { it.text.strip }
    assert_equal nav_labels, grouped, "a link outside a panel would be a destination with no category"
  end

  test "each workspace names its own categories" do
    {
      users(:instructor) => [ I18n.t("chrome.nav_group.teaching"), I18n.t("chrome.nav_group.university") ],
      users(:admin) => [ I18n.t("chrome.nav_group.administration"), I18n.t("chrome.nav_group.university") ],
      @company => [ I18n.t("chrome.nav_group.company"), I18n.t("chrome.nav_group.students") ]
    }.each do |user, expected|
      sign_in_as user
      get root_url
      follow_redirect! while response.redirect?

      assert_equal expected, nav_categories, "#{user.workspace} should sort its destinations its own way"
      sign_out
    end
  end

  # One landmark over the whole bar, one panel per category, and each panel its
  # own dropdown — which is what makes opening one close the others. The extra
  # dropdown is the compact button that replaces the bar below `md`.
  test "the menubar is one landmark with a dropdown per category" do
    sign_in_as @company
    get companies_url

    assert_select "nav[aria-label=?]", I18n.t("chrome.nav_label"), count: 1
    assert_select "[data-menu=nav][data-dropdown-target=panel]", count: nav_categories.length
    assert_select "nav[aria-label] [data-controller=dropdown]", count: nav_categories.length + 1
  end

  # A phone fits neither three category buttons nor the utility rail beside
  # them, so the bar becomes one button — carrying the same categories and the
  # same destinations, because both read `app_nav_groups`.
  test "the compact button offers exactly what the menubar does" do
    sign_in_as users(:one)
    get root_url

    assert_equal nav_labels, nav_compact_labels
    assert_equal nav_categories,
                 css_select("[data-menu=nav-compact] p").map { it.text.strip }
    assert_select "[data-menu=nav-compact][data-dropdown-target=panel]", count: 1
  end

  # The category a learner is inside is marked on the bar, so the current
  # section is legible without opening anything.
  test "the category holding the current screen is marked open on the bar" do
    sign_in_as users(:one)
    get progress_url

    marked = css_select("nav[aria-label] button[data-nav-group].bg-chrome-3").map { it["data-nav-group"] }
    assert_equal [ I18n.t("chrome.nav_group.track") ], marked
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
