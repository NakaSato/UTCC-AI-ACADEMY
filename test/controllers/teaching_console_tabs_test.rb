require "test_helper"

# The Teaching console's bar: which panel a tab opens, what stays above the bar
# whichever one is open, and the counts that ride on it.
#
# The panels themselves are tested where they were: the roster and the CSV in
# instructor_grades_test.rb, the switches in instructor_integrity_settings_test.rb,
# the course in teaching_course_authority_test.rb.
class TeachingConsoleTabsTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:instructor)
    @section = Section.for_staff(@teacher)
    sign_in_as @teacher
  end

  test "the figures and the export stay above the bar on every tab" do
    TeachingConsole::TABS.each do |tab|
      get instructor_url(tab:)

      assert_response :success
      assert_select "h1", text: I18n.t("instructor.title", course: @section.course.code)
      assert_select "a[href=?]", instructor_grades_path
      I18n.t("instructor.stats").each { assert_select "main", text: /#{Regexp.escape(it[:label])}/ }
    end
  end

  test "each tab opens its own panel and no other" do
    {
      roster: "instructor.roster_title",
      topics: "instructor.hardest_title",
      integrity: "instructor.integrity_settings_title",
      course: "instructor.course_title",
      syllabus: "instructor.syllabus_title"
    }.each do |tab, heading|
      get instructor_url(tab:)

      assert_response :success
      assert_select "main h2", { text: I18n.t(heading) },
                    "the #{tab} tab should show its own panel"
      assert_select "main h2", text: I18n.t("instructor.roster_title"), count: (tab == :roster ? 1 : 0)
    end
  end

  test "the roster is the tab a plain visit opens, and it is the URL's default" do
    get instructor_url

    assert_response :success
    assert_select "main nav a[aria-current=page]", text: /#{I18n.t("instructor.tabs.roster")}/
    # The default tab's link carries no query string — the bar links where the
    # screen already is, rather than to a longer spelling of the same URL.
    assert_select "main nav a[href=?]", instructor_path, text: /#{I18n.t("instructor.tabs.roster")}/
  end

  test "an unknown tab opens the roster rather than nothing" do
    get instructor_url(tab: "gradebook")

    assert_response :success
    assert_select "main nav a[aria-current=page]", text: /#{I18n.t("instructor.tabs.roster")}/
    assert_select "main h2", text: I18n.t("instructor.roster_title")
  end

  test "the roster pill counts the students who are behind, not the students" do
    report = InstructorReport.new(@section)
    behind = report.behind_count

    assert_equal roster_behind_count(report), behind, "behind is under the BEHIND line, not a roster size"
    assert_equal behind, TeachingConsole.badges(report:, integrity_settings: []).fetch(:roster)

    get instructor_url

    assert_response :success
    # One span is the label; a second is the pill. A tab with nothing to flag
    # wears no pill at all.
    assert_select "main nav a[aria-current=page] span", count: (behind.positive? ? 2 : 1)
    assert_select "main nav a[aria-current=page] span", text: behind.to_s if behind.positive?
  end

  test "the integrity pill counts the lessons whose log is hidden" do
    report = InstructorReport.new(@section)
    settings = LessonIntegritySetting.rows_for(@section.course)

    assert_equal 0, TeachingConsole.badges(report:, integrity_settings: settings).fetch(:integrity),
                 "nothing is hidden until a teacher hides it"

    LessonIntegritySetting.update!(course: @section.course, topic_key: "1-1",
                                   enabled: false, expected_lock_version: 0)

    get instructor_url(tab: :integrity)

    assert_response :success
    assert_select "main nav a[aria-current=page] span", text: "1"
  end

  test "a section with nothing to teach gets the notice and no bar at all" do
    sign_in_as users(:console_instructor)
    get instructor_url

    assert_response :success
    assert_select "h1", text: I18n.t("instructor.no_section.title")
    assert_select "main nav a", text: /#{I18n.t("instructor.tabs.roster")}/, count: 0
  end

  test "both languages name every tab" do
    %i[ en th ].each do |locale|
      TeachingConsole::TABS.each do |tab|
        assert I18n.t("instructor.tabs.#{tab}", locale:, default: nil).present?,
               "#{locale} is missing instructor.tabs.#{tab}"
      end
    end
  end

  private
    # The count spelled out from the rows, so the pill is checked against the
    # roster rather than against the method that draws it.
    def roster_behind_count(report)
      report.roster.count { it.percent < InstructorReport::BEHIND }
    end
end
