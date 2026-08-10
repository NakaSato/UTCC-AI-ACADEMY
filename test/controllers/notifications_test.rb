require "test_helper"

# Notifications are written where the action happens, so these tests drive the
# actions and read the bell — never Notification.create directly.
class NotificationsTest < ActionDispatch::IntegrationTest
  test "enrolling a student writes them a notification, once" do
    sign_in_as users(:admin)

    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }
    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }

    notes = users(:two).notifications
    assert_equal 1, notes.count, "the no-op re-enrol must not ping again"
    assert_equal "enrolled", notes.sole.kind
    assert_includes notes.sole.text, sections(:ba_2).label
  end

  test "a role grant tells the account, in the reader's language at read time" do
    sign_in_as users(:admin)
    patch admin_user_url(users(:one)), params: { role: "instructor" }

    note = users(:one).notifications.sole
    I18n.with_locale(:th) { assert_includes note.text, I18n.t("admin.roles.instructor") }
    I18n.with_locale(:en) { assert_includes note.text, "Instructor" }
  end

  test "notify-student and escalate write to the right people" do
    make_event(users(:one))
    sign_in_as users(:admin)

    post notify_integrity_case_url(users(:one))
    assert_equal "integrity_notice", users(:one).notifications.sole.kind

    post escalate_integrity_case_url(users(:one))
    note = users(:instructor).notifications.sole
    assert_equal "integrity_escalated", note.kind
    assert_includes note.text, users(:one).name
  end

  test "escalating with no instructor to send to is a flash, not a guess" do
    make_event(users(:one))
    sections(:ba_2).update!(instructor: nil)
    sign_in_as users(:admin)

    assert_no_difference -> { Notification.count } do
      post escalate_integrity_case_url(users(:one))
    end

    assert_equal I18n.t("flash.no_instructor", name: users(:one).name), flash[:alert]
  end

  test "acting on a case that closed under you says so" do
    sign_in_as users(:admin)

    assert_no_difference -> { Notification.count } do
      post notify_integrity_case_url(users(:one))
    end

    assert_equal I18n.t("flash.case_gone"), flash[:alert]
  end

  test "the bell shows unread rows and mark-all-read clears them" do
    sign_in_as users(:admin)
    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }

    sign_in_as users(:two)
    get root_url
    assert_select "header", text: /#{Regexp.escape(users(:two).notifications.sole.text)}/

    post read_notifications_url
    assert_equal 0, users(:two).notifications.unread.count

    # Someone else's mark-all-read must not touch other accounts.
    assert_equal 1, Notification.count
  end

  # Clearing a dropdown is not a navigation. A browser with Turbo gets the bell
  # back and a toast; the redirect is what is left for one without it.
  test "mark-all-read answers a Turbo request with a redrawn bell and a toast" do
    sign_in_as users(:admin)
    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }

    sign_in_as users(:two)
    post read_notifications_url, as: :turbo_stream

    assert_response :success
    assert_equal 0, users(:two).notifications.unread.count
    assert_select "turbo-stream[action=replace][target=?]", NotificationBell::ID
    assert_select "turbo-stream[action=toast][kind=success][target=toasts] template",
                  text: I18n.t("flash.notifications_read", locale: :th)
  end

  test "mark-all-read still redirects a browser that cannot take a stream" do
    sign_in_as users(:admin)
    post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }

    sign_in_as users(:two)
    post read_notifications_url, headers: { "Referer" => progress_url }

    assert_redirected_to progress_url
  end

  test "an empty bell says so instead of showing nothing" do
    sign_in_as users(:one)
    get root_url

    assert_select "header", text: /#{Regexp.escape(I18n.t("chrome.notif_empty"))}/
  end

  test "an academic-post invitation notification exposes only its acceptance link" do
    sign_in_as users(:two)
    token = "a" * 64
    Notification.notify(users(:two), "academic_post_invitation", token:, title: "Shared draft")

    get root_url

    assert_select "a[href=?]", academic_post_invitation_path(token),
                  text: I18n.t("notifications.academic_post_invitation_action")
  end

  private
    def make_event(user)
      ProctorEvent.create!(user:, course: Course.find_by!(code: "AI1101"),
                           topic: Topic.find_by!(key: "1-1"), kind: "blur", occurred_at: Time.current)
    end
end
