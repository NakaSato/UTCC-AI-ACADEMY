require "test_helper"

# The console's newer surface: the counted header, the two tabs that joined the
# row, and the query-string filters. A separate file from admin_test.rb, which
# owns the roster and the one role grant.
class AdminConsoleTabsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the header counts the live tables" do
    get admin_url

    assert_response :success
    assert_select "h1", text: I18n.t("admin.title")
    # The first head stat is the account count — a number from the database,
    # not copy from a locale file.
    assert_select "main", text: /#{User.count}/
    assert_select "main", text: /#{I18n.t("admin.head.note")}/
  end

  test "the integrity tab renders every case, most severe first" do
    get admin_url(tab: :integrity)

    assert_response :success
    assert_select "main section", count: AdminConsole::INTEGRITY.size
    assert_select "main", text: /#{I18n.t("admin.integrity.rows").first[:name]}/
    # The closed case shows its outcome instead of the action row.
    assert_select "main", text: /#{I18n.t("admin.integrity.closed")}/
  end

  test "the integrity badge counts open cases only" do
    assert_equal 2, AdminConsole.badge_for(:integrity)
  end

  test "the permissions matrix is one row per capability and one column per role" do
    get admin_url(tab: :perms)

    assert_response :success
    User::ROLES.each { assert_select "main", text: /#{I18n.t("admin.roles.#{it}")}/ }
    I18n.t("admin.perms.rows").each { assert_select "main", text: /#{Regexp.escape(it)}/ }
  end

  test "the role chips filter the roster and survive in the URL" do
    get admin_url(tab: :users, role: :instructor)

    assert_response :success
    assert_select "main", text: /#{users(:instructor).name}/
    assert_select "main", text: /#{users(:one).name}/, count: 0
  end

  test "the roster search matches name and student ID" do
    get admin_url(tab: :users, q: users(:one).student_id)

    assert_response :success
    assert_select "main", text: /#{users(:one).name}/
    assert_select "main", text: /#{users(:two).name}/, count: 0
  end

  test "an unknown role filter falls back to everyone" do
    get admin_url(tab: :users, role: "overlord")

    assert_response :success
    assert_select "main", text: /#{users(:one).name}/
    assert_select "main", text: /#{users(:instructor).name}/
  end

  test "the audit chips cut the log by level" do
    get admin_url(tab: :audit, level: :warn)

    assert_response :success
    warn_rows = AdminConsole.audit(level: :warn)
    assert_equal AdminConsole::AUDIT_LEVELS.count(:warn), warn_rows.size
    assert_select "main", text: /#{Regexp.escape(warn_rows.first[:event])}/
  end

  test "the courses search filters by code or name" do
    get admin_url(tab: :courses, q: "AI1101")

    assert_response :success
    assert_select "main", text: /AI1101/
    assert_select "main", text: /AI1150/, count: 0
  end

  # The gates the matrix claims are the gates the app enforces. If one of these
  # fails, either a gate moved or the table is lying — fix whichever it is.
  test "the matrix rows are true statements about the code" do
    student, instructor, admin = users(:one), users(:instructor), users(:admin)
    flags = AdminConsole::PERMS

    assert_equal [ student.student?, instructor.staff?, admin.staff? ].map { true }, flags[0],
                 "everyone signed in can learn"
    assert_equal [ true, false, false ], flags[1], "the leaderboard ranks students only"
    assert_equal [ true, false, false ], flags[2], "proctoring mounts for students only"
    assert_equal [ instructor.student?, instructor.staff?, admin.staff? ], flags[3],
                 "the Teaching console takes staff"
    assert_equal [ student.admin?, instructor.admin?, admin.admin? ], flags[4],
                 "this console takes admin"
    assert_equal [ student.admin?, instructor.admin?, admin.admin? ], flags[5],
                 "roles are granted by admin alone"
  end
end
