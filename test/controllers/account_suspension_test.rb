require "test_helper"

# Suspending an account keeps the row and takes the access — the same shape a
# retired lesson has (ADR-0055). A suspended learner's completions still count on
# the leaderboard and in their section's averages, because the work was done.
class AccountSuspensionTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @student = users(:one)
  end

  # ---- The write ------------------------------------------------------------

  test "an administrator suspends a selection, and every account gets its own audit row" do
    sign_in_as @admin

    assert_difference "AuditEvent.count", 2 do
      post admin_user_suspension_path, params: { user_ids: [ @student.id, users(:two).id ], suspend: "1" }
    end

    assert_redirected_to admin_path(tab: :users)
    assert_predicate @student.reload, :suspended?
    assert_predicate users(:two).reload, :suspended?
    # One row per person, never one per batch: the log answers "what happened to
    # this account", and "2 accounts suspended" answers it for nobody.
    assert_equal %w[ account_suspended account_suspended ], AuditEvent.newest_first.limit(2).map(&:action)
    assert_match @student.name, AuditEvent.newest_first.to_a.find { it.text.include?(@student.name) }.text
  end

  test "restoring gives the access back and says so" do
    @student.update!(suspended_at: Time.current)
    sign_in_as @admin

    post admin_user_suspension_path, params: { user_ids: [ @student.id ], restore: "1" }

    assert_not_predicate @student.reload, :suspended?
    assert_equal "account_restored", AuditEvent.newest_first.first.action
  end

  test "suspending an already suspended account writes nothing" do
    @student.update!(suspended_at: 1.day.ago)
    sign_in_as @admin

    assert_no_difference "AuditEvent.count" do
      post admin_user_suspension_path, params: { user_ids: [ @student.id ], suspend: "1" }
    end
  end

  test "an empty selection is refused rather than silently doing nothing" do
    sign_in_as @admin

    post admin_user_suspension_path, params: { suspend: "1" }

    assert_equal I18n.t("flash.accounts_none_selected"), flash[:alert]
  end

  # The last administrator locking themselves out is not a state they should be
  # able to reach by ticking a box.
  test "an administrator cannot suspend themselves" do
    sign_in_as @admin

    assert_no_difference "AuditEvent.count" do
      post admin_user_suspension_path, params: { user_ids: [ @admin.id, @student.id ], suspend: "1" }
    end

    assert_equal I18n.t("flash.account_self_suspend"), flash[:alert]
    assert_not_predicate @admin.reload, :suspended?
    assert_not_predicate @student.reload, :suspended?, "the whole batch is refused, not the rest of it"
  end

  test "suspension takes the admin role" do
    sign_in_as users(:instructor)

    post admin_user_suspension_path, params: { user_ids: [ @student.id ], suspend: "1" }

    assert_redirected_to root_path
    assert_not_predicate @student.reload, :suspended?
  end

  # ---- What suspension does -------------------------------------------------

  test "a suspended account cannot sign in, and is told why" do
    @student.update!(suspended_at: Time.current)

    post login_path, params: { student_id: @student.student_id, password: "password" }

    assert_redirected_to login_path
    assert_equal I18n.t("flash.account_suspended"), flash[:alert]
    assert_empty @student.sessions, "a refused sign-in must not leave a session behind"
  end

  test "a suspended console account cannot sign in either" do
    teacher = users(:instructor)
    teacher.update!(suspended_at: Time.current)

    # This fixture signs in by student ID — `credentials` tells the three
    # identifiers apart by shape, and an all-digit one is a student ID.
    post console_path, params: { identifier: teacher.student_id, password: "password" }

    assert_redirected_to console_path
    assert_equal I18n.t("flash.account_suspended"), flash[:alert]
  end

  # The half a "cannot sign in" check on its own would miss.
  test "suspension ends the session an account already had open" do
    sign_in_as @student
    # A screen that actually requires a session: `/` is
    # `allow_unauthenticated_access` and answers 200 to anybody, so it would have
    # passed this test without proving a thing.
    get progress_path
    assert_response :success

    @student.update!(suspended_at: Time.current)

    get progress_path
    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  test "restoring lets them back in" do
    @student.update!(suspended_at: Time.current)
    @student.update!(suspended_at: nil)

    post login_path, params: { student_id: @student.student_id, password: "password" }

    assert_redirected_to root_url
  end

  # ---- What suspension does not do ------------------------------------------

  test "a suspended learner keeps every record they own" do
    TopicCompletion.create!(user: @student, course: courses(:ai1101), topic: topics(:topic_1_1),
                            learned_at: Time.current)
    completions = TopicCompletion.where(user: @student).count

    @student.update!(suspended_at: Time.current)

    assert_equal completions, TopicCompletion.where(user: @student).count
    assert_equal @student.name, User.find(@student.id).name
  end

  test "the roster shows the status and offers the selection" do
    @student.update!(suspended_at: Time.current)
    sign_in_as @admin

    get admin_url(tab: :users)

    assert_response :success
    assert_select "main", text: /#{I18n.t("admin.status.suspended")}/
    assert_select "input[type=checkbox][name=?][value=?]", "user_ids[]", @student.id.to_s
    assert_select "input[type=submit][name=suspend]"
    assert_select "input[type=submit][name=restore]"
  end

  test "both locales carry the status and the bulk bar" do
    %i[ en th ].each do |locale|
      %w[ th_status status.active status.suspended bulk.label bulk.suspend bulk.restore ].each do |key|
        assert I18n.t("admin.#{key}", locale:, default: nil).present?, "#{locale} is missing admin.#{key}"
      end
      assert I18n.t("flash.account_suspended", locale:, default: nil).present?
    end
  end
end
