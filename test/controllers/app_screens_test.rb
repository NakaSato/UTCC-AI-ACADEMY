require "test_helper"

# Every screen of the app UI, signed in. These are reachability and
# content-shape tests: the placeholder data sources are covered separately in
# test/models, so this file only asserts that each screen renders the thing its
# route promises.
class AppScreensTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    FeatureSetting.find_by!(key: "leaderboard").update!(enabled: true)
  end

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
      assert_select "[role=tabpanel][data-motion]", LessonContent::STEPS.size
      assert_select "[data-panels-target~=progress][style*='width:']", 1
      assert_select "[data-panels-target~=stepLabel][data-lesson-step-label]", LessonContent::STEPS.size
      assert_select "[data-proctor-target~=score][data-integrity-score]", 1
      assert_select "[data-proctor-target~=meter][data-integrity-meter]", 1
      assert_select "[data-proctor-target~=verdict][data-integrity-verdict]", 1
      assert_select "[data-proctor-target~=guard][data-integrity-guard]", 1
      assert_select "[data-proctor-target~=guardDialog][data-integrity-guard-dialog]", 1
      assert_select "template[data-proctor-target~=row] [data-integrity-event-row]", 1
      assert_select "[role=tab] [data-panels-target~=stepIndicator][data-lesson-step-indicator]",
                    LessonContent::STEPS.size
      assert_select "[data-panel=summary] [data-panels-target~=summaryMark][data-summary-mark]", 1
      assert_select "[data-panel=summary] [data-panels-target~=summaryReward][data-summary-reward]",
                    LessonContent.rewards.size
      assert_select "[data-panel=summary] a[data-panels-target~=summaryAction][data-summary-action]", 2
      assert_select "a[data-assessment-action][data-quiz-target~=next]", 1
      assert_select "a[data-assessment-action][data-code-task-target~=finish]", 1
      assert_select "[data-quiz-target~=option] [data-quiz-choice-indicator]",
                    LessonContent.for(Syllabus.topic_keys.first).options.size
    end
  end

  # Grading and proctoring both run in the browser, so the server's whole job
  # here is to hand the controller its copy and its weights.
  test "the theory step renders every free-form block" do
    get lesson_url

    assert_response :success
    content = LessonContent.for(Syllabus.topic_keys.first)
    content.blocks.each do |block|
      assert_select "[data-panel=theory]", text: /#{Regexp.escape(block.value.lines.first.strip)}/
    end
    assert_select "a[href=?]", content.blocks.find { it.type == :link }.extra
  end

  # An equation block is typeset when it is LaTeX and printed when it is not, and
  # the server is what decides — the browser only carries it out. Topic 5-2 falls
  # back to the placeholder copy, whose equation really is LaTeX and was rendered
  # to learners as `\lceil 0.8\,N \rceil` until KaTeX was wired up; topic 1-1
  # carries a prose formula that typesetting would ruin.
  #
  # The source is in the markup either way, so a reader with no JavaScript sees
  # the expression rather than an empty plate.
  test "a LaTeX equation block is handed to KaTeX and a prose one is not" do
    # 5-2 is behind the progression gate, and this test is about what it renders
    # rather than about reaching it.
    complete_topics(users(:one), "AI1101", Syllabus.topic_keys.take_while { it != "5-2" })

    get lesson_url(course: "AI1101", topic: "5-2")

    assert_response :success
    latex = LessonContent.for("5-2").blocks.find(&:latex?)
    assert_not_nil latex, "topic 5-2 is the placeholder copy, whose equation block is LaTeX"
    assert_select "[data-controller=katex][data-katex-source-value=?]", latex.value
    assert_select "[data-controller=katex]", text: latex.value,
      message: "the source stays on the page for a reader without JavaScript"

    get lesson_url(course: "AI1101", topic: "1-1")

    assert_response :success
    assert_select "[data-controller=katex]", count: 0,
      message: "a prose formula must not be typeset — KaTeX would italicise every word in it"
  end

  test "student proctoring is on without a lesson-page switch and staff are exempt" do
    get lesson_url

    assert_response :success
    assert_select "main[data-controller*=proctor]", 1
    assert_select "main[data-proctor=on]", 1
    assert_select "button[data-proctor-target=switch]", count: 0

    sign_in_as users(:instructor)
    get lesson_url

    assert_response :success
    assert_select "main[data-controller*=proctor]", count: 0
    assert_select "main", text: /#{I18n.t("lesson.proctor.label_exempt")}/
  end

  test "the integrity log restores stored assessment events in the selected language" do
    event = ProctorEvent.create!(user: users(:one), course: courses(:ai1101), topic: topics(:topic_1_1),
                                 kind: "blur", occurred_at: Time.zone.parse("2026-08-15 08:05:04"))
    ProctorEvent.create!(user: users(:two), course: courses(:ai1101), topic: topics(:topic_1_1),
                         kind: "capture", occurred_at: event.occurred_at)
    ProctorEvent.create!(user: users(:one), course: courses(:ai1101), topic: topics(:topic_1_2),
                         kind: "print", occurred_at: event.occurred_at)
    lesson = lesson_url(course: "AI1101", topic: "1-1", step: :exercise)

    get lesson

    assert_response :success
    assert_integrity_state(event:, locale: :th, score: 92)

    # The language write redirects back to this lesson. The event is read from
    # the database again and its sentence is rendered in the new locale.
    post language_url(:en), headers: { "HTTP_REFERER" => lesson }
    follow_redirect!

    assert_select "html[lang=en]"
    assert_integrity_state(event:, locale: :en, score: 92)
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

    # One topic of AI1101 finished, every topic of AI1102 — one course in each
    # list.
    complete_topics(users(:one), "AI1101", Syllabus.topic_keys.first(1))
    complete_topics(users(:one), "AI1102", Syllabus.topic_keys("AI1102"))

    get my_learning_url

    assert_response :success
    assert_select "#{in_progress}", text: /#{Regexp.escape(I18n.t("catalog.courses.AI1101.title"))}/
    assert_select "[role=tabpanel][data-panel=progress]:not([hidden])", 1
    # The completed list is in the page too, just hidden until the tab is used.
    assert_select "#{completed}", text: /#{Regexp.escape(I18n.t("catalog.courses.AI1102.title"))}/
    assert_select "[role=tabpanel][data-panel=done][hidden]", 1
    assert_select "details[data-controller=disclosure-motion][data-enrollment-course]", 2 do
      assert_select "[data-disclosure-motion-target=content][data-enrollment-content]", 2
    end

    get my_learning_url(tab: "done")

    assert_response :success
    assert_select "[role=tabpanel][data-panel=done]:not([hidden])", 1
    assert_select "[role=tabpanel][data-panel=progress][hidden]", 1
  end

  test "the map expands the ancestors of the selected topic" do
    topic = Syllabus.topics("AI1101").first
    get knowledge_map_url(course: "AI1101", topic: topic.key)

    assert_response :success
    # The breadcrumb is the path from the root to the selection.
    assert_select "nav a", text: I18n.t("catalog.courses.AI1101.title")
    assert_select "nav a", text: Syllabus.modules(Set.new, "AI1101").first.title
    # A leaf shows its own detail card rather than child cards.
    assert_select "h2", text: Syllabus.modules(Set.new, "AI1101").first.topics.first.name
  end

  test "the map falls back to the default selection for an unknown topic" do
    get knowledge_map_url(course: "AI1101", topic: "does-not-exist")

    assert_response :success
    assert_select "h2", text: Syllabus.modules(Set.new, "AI1101").first.topics.first.name
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
    # Twice: once in the menubar's category panel, once in the compact button
    # that replaces the bar below `md`. Both render `app_nav_groups`.
    assert_select "header a[href=?]", admin_path, count: 2
    assert_select "header a[href=?]", companies_path, count: 2
    # /instructor is a report on a section an admin does not teach, so the nav
    # does not offer it — the route still admits them if they type it.
    assert_select "header a[href=?]", instructor_path, count: 0
  end

  # An admin's nav is the admin screen and the company list, and nothing else:
  # `/` only bounces them back to /admin, so the catalog and the learner screens
  # are not theirs.
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

    [ course_url("AI1101"), lesson_url, my_learning_url, profile_url, knowledge_map_url,
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
    assert_select "#tracks[data-controller=tabs]" do
      assert_select "[role=tab][data-tabs-target=tab][aria-selected]", Landing.track_filters.size
      assert_select "[data-tabs-target=item][data-track-card][data-level]", Landing.tracks.size
    end
    assert_select "#faq details[data-controller=disclosure-motion][data-faq-disclosure]", Landing.faqs.size do
      assert_select "[data-disclosure-motion-target=content][data-faq-answer]", Landing.faqs.size
    end
    assert_select "header[data-controller=header][data-pinned=false][data-header-pinned-class]", 1
    assert_select "a[data-header-target=navLink][data-scroll-spy-link][data-active=false]", 10
    assert_select "button[data-header-target=toggle][aria-controls=landing-menu][aria-expanded=false]", 1
    assert_select "[data-mobile-drawer][data-state=closed][data-open=false][hidden]", 1 do
      assert_select "[data-header-target=drawerBackdrop][data-mobile-drawer-backdrop]", 1
      assert_select "#landing-menu[data-header-target=drawerPanel][data-mobile-drawer-panel]", 1
    end
  end

  private
    def assert_integrity_state(event:, locale:, score:)
      main = css_select("main[data-proctor-initial-events-value][data-proctor-score-value]").sole
      entries = JSON.parse(main["data-proctor-initial-events-value"])

      assert_equal score.to_s, main["data-proctor-score-value"]
      assert_equal Proctoring::ACTIVE_STEPS.to_json, main["data-proctor-active-steps-value"]
      assert_equal 1, entries.size
      assert_equal event.kind, entries.first.fetch("kind")
      assert_equal I18n.t("lesson.proctor.events.#{event.kind}", locale:), entries.first.fetch("text")
      assert_equal "08:05:04", entries.first.fetch("stamp")

      log = css_select("[data-integrity-log]").sole
      assert_includes log["class"], "group-data-[panel=exercise]:block"
      assert_includes log["class"], "group-data-[panel=code]:block"
    end
end
