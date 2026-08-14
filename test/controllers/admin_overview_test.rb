require "test_helper"

# The Overview tab below its four counted tiles. The tab used to be the tiles and
# a note promising "other operational views when their data sources are defined";
# these are those views, and the test that matters most is that each is counted
# off records rather than written down.
class AdminOverviewTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "every panel renders on the overview tab" do
    get admin_url(tab: :overview)

    assert_response :success
    [ "adoption_title", "activity_title", "duplicates_title" ].each do
      assert_select "main h2", text: I18n.t("admin.overview.#{it}")
    end
    assert_select "main h2", text: I18n.t("admin.overview.health.title")
    assert_select "main h2", text: I18n.t("admin.overview.reports_title")
  end

  # ---- Adoption -------------------------------------------------------------

  test "adoption counts every faculty, and every account in it" do
    units = AdminOverview.adoption

    assert_equal User.count, units.sum(&:total), "every account belongs to exactly one row"
    assert_equal User.distinct.count(:faculty) + (User.where(faculty: nil).exists? ? 1 : 0), units.size
    assert units.all? { it.pct.between?(0, 100) }
  end

  # Sessions are never touched after they are created (see Session::MAX_AGE), so
  # a week-old session is not evidence of a quiet user — but a topic finished
  # this morning is.
  test "activity in any of the four sources counts as active" do
    student = users(:one)
    Session.where(user: student).delete_all
    TopicCompletion.where(user: student).delete_all
    Submission.where(user: student).delete_all
    AuditEvent.where(user: student).delete_all

    assert_not_includes AdminOverview.active_user_ids, student.id

    TopicCompletion.create!(user: student, course: courses(:ai1101), topic: topics(:topic_1_1),
                            learned_at: Time.current)

    assert_includes AdminOverview.active_user_ids, student.id
  end

  test "activity older than the window does not count" do
    student = users(:one)
    Session.where(user: student).delete_all
    TopicCompletion.where(user: student).delete_all
    Submission.where(user: student).delete_all
    AuditEvent.where(user: student).delete_all
    Session.create!(user: student, created_at: (AdminOverview::WINDOW + 1.day).ago, ip_address: "1.1.1.1")

    assert_not_includes AdminOverview.active_user_ids, student.id
  end

  # ---- Activity feed --------------------------------------------------------

  test "the feed shows the newest audit rows and names who did them" do
    AuditEvent.create!(user: users(:admin), action: "role_changed",
                       params: { name: "Somebody", role: "instructor" })

    get admin_url(tab: :overview)

    assert_response :success
    assert_select "main", text: /#{users(:admin).name}/
    assert_operator AdminOverview.activity.size, :<=, AdminOverview::ACTIVITY_LIMIT
  end

  test "initials survive a script with no capitals" do
    assert_equal "อค", AdminOverview.initials("อาจารย์ คอนโซล")
    assert_equal "?", AdminOverview.initials("")
  end

  # ---- Duplicates -----------------------------------------------------------

  test "two accounts with one name are a finding, one account is not" do
    assert_not_predicate AdminOverview.duplicates, :any?, "the fixtures should not start with a collision"

    make_twin

    found = AdminOverview.duplicates
    assert_equal 1, found.names
    assert_equal 2, found.accounts
  end

  # SPEC-0012 invariant 5: this boundary returns aggregate values and approved
  # labels, not raw learner records or private identifiers. The panel says how
  # many names collide; the roster is where accounts are read.
  test "the finding names nobody and offers no merge" do
    twin = make_twin

    get admin_url(tab: :overview)

    assert_response :success
    assert_select "a[href=?]", admin_path(tab: :users, sort: :name)

    panel = css_select("main").text
    assert_includes panel, I18n.t("admin.overview.duplicates_count", names: 1, accounts: 2)
    assert_not_includes panel, twin.student_id, "a student ID must not reach the Overview"
    assert_not_includes panel, twin.email_address, "an email must not reach the Overview"
    # Merging moves enrollments, completions, submissions and memberships and
    # decides which identity survives. There is no button for that, on purpose.
    assert_select "main form[action*=merge]", count: 0
  end

  # ---- Service status -------------------------------------------------------

  test "every check answers, and the database is up while the test is running" do
    checks = AdminOverview.health

    assert_equal %i[ database jobs cache storage ], checks.map(&:key)
    assert checks.all? { %i[ ok warn down unknown ].include?(it.state) }
    assert_equal :ok, checks.first.state, "the suite cannot run without a database"
  end

  # A status panel that 500s is the one failure mode a status panel may not have,
  # so every check runs through one rescue.
  test "a check that raises reports down rather than breaking the page" do
    check = AdminOverview.check(:storage) { raise IOError, "no disk" }

    assert_equal :storage, check.key
    assert_equal :down, check.state
    assert_equal "IOError", check.note

    get admin_url(tab: :overview)
    assert_response :success
  end

  # ---- Reports --------------------------------------------------------------

  test "each report downloads a real CSV of real rows" do
    AdminOverview::REPORTS.each do |key|
      get admin_report_url(key)

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.media_type + "; charset=" + response.charset
      assert_match(/attachment; filename=/, response.headers["Content-Disposition"])

      body = response.body.delete_prefix("﻿")
      assert_equal I18n.t("admin.overview.columns.#{key}").join(","), body.lines.first.chomp
    end
  end

  test "the accounts report has one row per account" do
    get admin_report_url("accounts")

    assert_equal User.count + 1, response.body.lines.size
    assert_match users(:one).name, response.body
  end

  test "a report nobody defined is not a report" do
    get admin_report_url("everything")

    assert_redirected_to admin_path(tab: :overview)
  end

  test "a report takes the admin role" do
    sign_in_as users(:instructor)
    get admin_report_url("accounts")

    assert_redirected_to root_path
  end

  test "both locales carry every panel's copy" do
    %i[ en th ].each do |locale|
      %w[ adoption_title adoption_sub activity_title duplicates_title reports_title ].each do |key|
        assert I18n.t("admin.overview.#{key}", locale:, default: nil).present?,
               "#{locale} is missing admin.overview.#{key}"
      end
      AdminOverview::REPORTS.each do |key|
        assert I18n.t("admin.overview.reports.#{key}", locale:, default: nil).present?
        assert_equal 4, I18n.t("admin.overview.columns.#{key}", locale:).size if key == "audit"
      end
    end
  end

  private
    def make_twin
      users(:one).dup.tap do |twin|
        twin.assign_attributes(student_id: "2011071739999", username: nil, email_address: "twin@utcc.ac.th")
        twin.save!
      end
    end
end
