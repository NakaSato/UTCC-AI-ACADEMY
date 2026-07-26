require "test_helper"

# Every screen of the app UI, signed in. These are reachability and
# content-shape tests: the placeholder data sources are covered separately in
# test/models, so this file only asserts that each screen renders the thing its
# route promises.
class AppScreensTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  def complete_topics(user, code, keys)
    keys.each { TopicCompletion.record(user:, course_code: code, topic_key: it, kind: :learned) }
  end

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
    assert_select "details", count: Syllabus.entries.size
  end

  # Without a `?module=` the open one is where the learner is: module 1 for an
  # account that has finished nothing.
  test "the open module is the one the learner is on" do
    get course_url("AI1101")

    assert_response :success
    assert_select "details[open] p", text: Syllabus.modules.first.desc

    complete_topics(users(:one), "AI1101", Syllabus.keys_in(1))
    get course_url("AI1101")

    assert_select "details[open] p", text: Syllabus.modules.second.desc
  end

  test "the syllabus links the topics a learner can open and not the locked ones" do
    open_key, locked_key = Syllabus.keys_in(1).first, Syllabus.keys_in(3).first

    get course_url("AI1101")

    assert_response :success
    assert_select "a[href=?]", lesson_path(course: "AI1101", topic: open_key)
    assert_select "a[href=?]", lesson_path(course: "AI1101", topic: locked_key), count: 0

    complete_topics(users(:one), "AI1101", [ open_key ])
    get course_url("AI1101")

    # Finished topics are still linked — going back over one is allowed.
    assert_select "a[href=?]", lesson_path(course: "AI1101", topic: open_key)
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

  # Grading and proctoring both run in the browser, so the server's whole job
  # here is to hand the controller its copy and its weights.
  test "the theory step renders every free-form block" do
    get lesson_url

    assert_response :success
    LessonContent.blocks.each do |block|
      assert_select "[data-panel=theory]", text: /#{Regexp.escape(block.value.lines.first.strip)}/
    end
    assert_select "a[href=?]", LessonContent.blocks.find { it.type == :link }.extra
  end

  test "a student gets the proctor controller and staff get the exempt notice" do
    get lesson_url

    assert_response :success
    assert_select "main[data-controller*=proctor]", 1
    assert_select "main", text: /#{I18n.t("lesson.proctor.label_on")}/

    sign_in_as users(:instructor)
    get lesson_url

    assert_response :success
    assert_select "main[data-controller*=proctor]", count: 0
    assert_select "main", text: /#{I18n.t("lesson.proctor.label_exempt")}/
  end

  # A lesson is a position in a syllabus, and without a `?topic=` that position
  # is wherever the learner left off.
  test "the lesson opens on the next unfinished topic" do
    get lesson_url
    assert_response :success
    assert_select "main[data-lesson-topic=?]", Syllabus.topic_keys.first

    complete_topics(users(:one), "AI1101", Syllabus.topic_keys.first(2))
    get lesson_url

    assert_response :success
    assert_select "main[data-lesson-topic=?]", Syllabus.topic_keys.third
  end

  test "the lesson opens the topic it is asked for, and its links keep it" do
    key = Syllabus.keys_in(1).last
    get lesson_url(topic: key, step: :exercise)

    assert_response :success
    assert_select "main[data-lesson-topic=?]", key
    # Every step link carries the topic, or stepping through would jump forward.
    assert_select "a[href=?]", lesson_path(course: "AI1101", topic: key, step: :code)
  end

  test "a locked topic is turned away and an unknown one is not found" do
    get lesson_url(topic: Syllabus.keys_in(3).first)

    assert_redirected_to course_path("AI1101")
    assert_equal I18n.t("flash.topic_locked"), flash[:alert]

    get lesson_url(topic: "99-9")

    assert_redirected_to course_path("AI1101")
    assert_equal I18n.t("flash.topic_missing"), flash[:alert]
  end

  test "the lesson can be about another course, and refuses one that does not exist" do
    get lesson_url(course: "AI2402")

    assert_response :success
    assert_select "a[href=?]", course_path("AI2402")

    get lesson_url(course: "NOPE")

    assert_redirected_to root_path
    assert_equal I18n.t("flash.course_missing"), flash[:alert]
  end

  test "an unknown lesson step falls back to the first one" do
    get lesson_url(step: "nonsense")

    assert_response :success
    assert_select "[role=tab][aria-selected=true]", text: /#{I18n.t("lesson.steps.theory")}/
    assert_select "[role=tabpanel][data-panel=theory]:not([hidden])", 1
  end

  test "my learning is empty until something has been finished" do
    get my_learning_url

    assert_response :success
    assert_select "[data-panel=progress]", text: /#{I18n.t("my_learning.empty.progress")}/
    assert_select "[data-panel=done]", text: /#{I18n.t("my_learning.empty.done")}/
    assert_select "[data-panel=progress] summary", count: 0
  end

  test "my learning switches between in-progress and completed" do
    in_progress = "[data-panel=progress] summary"
    completed = "[data-panel=done] summary"

    # One topic of AI1101 finished, every topic of AI2402 — one course in each
    # list.
    complete_topics(users(:one), "AI1101", Syllabus.topic_keys.first(1))
    complete_topics(users(:one), "AI2402", Syllabus.topic_keys)

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
      progress_url => I18n.t("progress.greeting", name: users(:one).first_name),
      leaderboard_url => I18n.t("leaderboard.title")
    }.each do |url, heading|
      get url

      assert_response :success
      assert_select "h1", text: heading
    end
  end

  test "the staff screens render for the roles that own them" do
    {
      users(:instructor) => { instructor_url => I18n.t("instructor.title", course: "AI1101") },
      users(:admin) => { instructor_url => I18n.t("instructor.title", course: "AI1101"),
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
  end

  # An admin's nav is the two staff screens and nothing else: `/` only bounces
  # them back to /admin, so the catalog and the learner screens are not theirs.
  test "the admin nav drops the learner screens" do
    sign_in_as users(:admin)
    get admin_url

    assert_response :success
    [ my_learning_path, course_path("AI1101"), lesson_path,
      knowledge_map_path, progress_path, leaderboard_path ].each do |path|
      assert_select "header nav a[href=?]", path, count: 0
    end
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
      assert_redirected_to root_path, "#{url} should require authentication"
      assert_equal I18n.t("flash.sign_in_required"), flash[:alert], url
    end
  end

  # Denial goes to the landing page rather than the form, so signing in is now a
  # second hop. The stashed URL has to survive it, or every deep link into the
  # app quietly lands the visitor on the catalog instead of where they were going.
  test "a deep link survives the detour through the landing page" do
    sign_out

    get progress_url
    assert_redirected_to root_path

    post login_path, params: { student_id: users(:one).student_id, password: "password" }
    assert_redirected_to progress_url
  end

  test "root is the public landing page when signed out" do
    sign_out
    get root_url

    assert_response :success
    assert_select "h1", text: I18n.t("catalog.title"), count: 0
  end
end
