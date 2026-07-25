require "test_helper"

# Every screen of the app UI, signed in. These are reachability and
# content-shape tests: the placeholder data sources are covered separately in
# test/models, so this file only asserts that each screen renders the thing its
# route promises.
class AppScreensTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "root shows the catalog to a signed-in student" do
    get root_url

    assert_response :success
    assert_select "h1", text: I18n.t("catalog.title")
    # Every course, plus the "not sure where to start" card.
    assert_select "a[href=?]", course_path("AI1101")
  end

  test "catalog filters down to the requested tag" do
    get root_url(filter: :ethics)

    assert_response :success
    # Scoped to the card grid: the header nav links to AI1101 on every screen.
    assert_select "main h2", text: I18n.t("catalog.courses.AI2402.title")
    assert_select "main h2", text: I18n.t("catalog.courses.AI1101.title"), count: 0
  end

  test "an unknown filter falls back to showing everything" do
    get root_url(filter: "nonsense")

    assert_response :success
    assert_select "main h2", text: I18n.t("catalog.courses.AI1101.title")
    assert_select "main h2", text: I18n.t("catalog.courses.AI2402.title")
  end

  test "root sends an admin to the admin screen instead of the catalog" do
    sign_in_as users(:admin)
    get root_url

    assert_redirected_to admin_path

    follow_redirect!
    assert_select "h1", text: I18n.t("admin.title")
  end

  test "course page renders the syllabus" do
    get course_url("AI1101")

    assert_response :success
    assert_select "h1", text: I18n.t("catalog.courses.AI1101.title")
    assert_select "details", count: Syllabus::ENTRIES.size
  end

  test "an unknown course code redirects to the catalog" do
    get course_url("NOPE")

    assert_redirected_to root_path
    assert_equal I18n.t("flash.course_missing"), flash[:alert]
  end

  # Every step ships with the page — the sidebar switches panels in the browser
  # — so `step` decides which one starts visible, not which one is rendered.
  test "each lesson step opens on its own panel" do
    LessonContent::STEPS.each do |step|
      get lesson_url(step: step)

      assert_response :success
      assert_select "[role=tab][aria-selected=true]", text: /#{I18n.t("lesson.steps.#{step}")}/
      assert_select "[role=tabpanel]:not([hidden])", 1
      assert_select "[role=tabpanel][data-panel=#{step}]:not([hidden])", 1
      assert_select "[role=tabpanel]", LessonContent::STEPS.size
    end
  end

  test "an unknown lesson step falls back to the first one" do
    get lesson_url(step: "nonsense")

    assert_response :success
    assert_select "[role=tab][aria-selected=true]", text: /#{I18n.t("lesson.steps.theory")}/
    assert_select "[role=tabpanel][data-panel=theory]:not([hidden])", 1
  end

  test "my learning switches between in-progress and completed" do
    in_progress = "[data-panel=progress] summary"
    completed = "[data-panel=done] summary"

    get my_learning_url

    assert_response :success
    assert_select "#{in_progress}", text: /#{Regexp.escape(I18n.t("catalog.courses.AI1101.title"))}/
    assert_select "[role=tabpanel][data-panel=progress]:not([hidden])", 1
    # The completed list is in the page too, just hidden until the tab is used.
    assert_select "#{completed}", text: /#{Regexp.escape(I18n.t("catalog.courses.AI2402.title"))}/
    assert_select "[role=tabpanel][data-panel=done][hidden]", 1

    get my_learning_url(tab: "done")

    assert_response :success
    assert_select "[role=tabpanel][data-panel=done]:not([hidden])", 1
    assert_select "[role=tabpanel][data-panel=progress][hidden]", 1
  end

  test "the map expands the ancestors of the selected topic" do
    get knowledge_map_url(topic: "ml-split")

    assert_response :success
    # The breadcrumb is the path from the root to the selection.
    assert_select "nav a", text: I18n.t("map.nodes.cs")
    assert_select "nav a", text: I18n.t("map.nodes.ml-prep")
    # A leaf shows its own detail card rather than child cards.
    assert_select "h2", text: I18n.t("map.nodes.ml-split")
  end

  test "the map falls back to the default selection for an unknown topic" do
    get knowledge_map_url(topic: "does-not-exist")

    assert_response :success
    assert_select "nav a", text: I18n.t("map.nodes.#{KnowledgeMap::DEFAULT_SELECTED}")
  end

  test "progress and leaderboard screens render" do
    {
      progress_url => I18n.t("progress.greeting"),
      leaderboard_url => I18n.t("leaderboard.title")
    }.each do |url, heading|
      get url

      assert_response :success
      assert_select "h1", text: heading
    end
  end

  test "the staff screens render for the roles that own them" do
    {
      users(:instructor) => { instructor_url => I18n.t("instructor.title") },
      users(:admin) => { instructor_url => I18n.t("instructor.title"),
                         admin_url => I18n.t("admin.title") }
    }.each do |user, screens|
      sign_in_as user

      screens.each do |url, heading|
        get url

        assert_response :success, "#{user.role} should reach #{url}"
        assert_select "h1", text: heading
      end
    end
  end

  test "a student is turned away from the staff screens" do
    [ instructor_url, admin_url ].each do |url|
      get url

      assert_redirected_to root_path, "#{url} should be closed to a student"
      assert_equal(I18n.t("flash.forbidden"), flash[:alert])
    end
  end

  test "an instructor is turned away from the admin screen" do
    sign_in_as users(:instructor)
    get admin_url

    assert_redirected_to root_path
    assert_equal(I18n.t("flash.forbidden"), flash[:alert])
  end

  test "the nav offers only the screens the signed-in role can open" do
    get root_url

    assert_response :success
    assert_select "header a[href=?]", instructor_path, count: 0
    assert_select "header a[href=?]", admin_path, count: 0

    sign_in_as users(:admin)
    get admin_url

    assert_response :success
    # Once in the nav rail, once in the burger drawer.
    assert_select "header a[href=?]", instructor_path, count: 2
    assert_select "header a[href=?]", admin_path, count: 2
    # The admin entry takes the catalog's slot rather than sitting beside it.
    assert_select "header a", text: I18n.t("chrome.nav.catalog"), count: 0
  end

  test "the leaderboard marks the selected range and falls back to the first" do
    Leaderboard::TABS.each do |tab|
      get leaderboard_url(tab: tab)

      assert_response :success
      assert_select "[role=tab][aria-selected=true]", text: Leaderboard.tab_labels[tab]
    end

    get leaderboard_url(tab: "decade")

    assert_response :success
    assert_select "[role=tab][aria-selected=true]", text: Leaderboard.tab_labels[Leaderboard::TABS.first]
  end

  test "every app screen requires a session" do
    sign_out

    [ course_url("AI1101"), lesson_url, my_learning_url, knowledge_map_url,
      progress_url, leaderboard_url, instructor_url, admin_url ].each do |url|
      get url
      assert_redirected_to login_path, "#{url} should require authentication"
    end
  end

  test "root is the public landing page when signed out" do
    sign_out
    get root_url

    assert_response :success
    assert_select "h1", text: I18n.t("catalog.title"), count: 0
  end
end
