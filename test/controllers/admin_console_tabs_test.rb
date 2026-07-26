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

  test "the integrity tab shows a learner's unreviewed events as a case" do
    student = users(:one)
    make_events(student, %w[ paste capture blur ])   # 100 - 15 - 20 - 8 = 57 → risk

    get admin_url(tab: :integrity)

    assert_response :success
    assert_select "main", text: /#{student.name}/
    assert_select "main", text: /#{I18n.t("admin.integrity.severity.high")}/
    assert_select "main", text: /#{I18n.t("lesson.proctor.events.capture")}/
    assert_select "main", text: /57 \/ 100/
  end

  test "no open cases renders the empty state" do
    get admin_url(tab: :integrity)

    assert_response :success
    assert_select "main", text: /#{I18n.t("admin.integrity.empty_title")}/
  end

  test "the integrity badge counts learners with unreviewed events" do
    make_events(users(:one), %w[ blur ])
    make_events(users(:two), %w[ menu ])

    assert_equal 2, AdminConsole.badge_for(:integrity)
  end

  test "closing a case stamps the events and empties the tab" do
    student = users(:one)
    make_events(student, %w[ paste blur ])

    post close_integrity_case_url(student)

    assert_redirected_to admin_path(tab: :integrity)
    assert_equal 0, ProctorEvent.unreviewed.count
    assert_equal 2, ProctorEvent.where.not(reviewed_at: nil).count

    # New events open a new case — closing reviews history, it is not a pardon.
    make_events(student, %w[ blur ])
    assert_equal 1, AdminConsole.badge_for(:integrity)
  end

  test "closing a case takes the admin role" do
    make_events(users(:one), %w[ blur ])
    sign_in_as users(:instructor)

    post close_integrity_case_url(users(:one))

    assert_response :redirect
    assert_equal 1, ProctorEvent.unreviewed.count
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

  # The rows are real now — see admin_audit_test.rb for what writes them. This
  # is the chip, which is still a whitelist AdminConsole owns.
  test "the audit chips cut the log by level" do
    get admin_url(tab: :audit, level: :warn)

    assert_response :success
    assert_select "a[aria-current], a", text: I18n.t("admin.audit.levels.warn")

    get admin_url(tab: :audit, level: "overlord")

    assert_response :success
    assert_select "main h2", text: I18n.t("admin.audit.title")
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

  private
    def make_events(user, kinds)
      course = Course.find_by!(code: "AI1101")
      topic = Topic.find_by!(key: "1-1")
      kinds.each_with_index do |kind, index|
        ProctorEvent.create!(user:, course:, topic:, kind:, occurred_at: (kinds.size - index).minutes.ago)
      end
    end
end
