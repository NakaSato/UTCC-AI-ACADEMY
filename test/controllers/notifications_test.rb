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
    assert_select "[data-controller~=notification-bell][data-notification-bell-unread-value=true]" do
      assert_select "svg[data-notification-bell-target=icon]", count: 1
    end

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

    assert_select "header button[aria-label=?] svg[data-icon=notification-bell]",
                  I18n.t("chrome.notif_toggle"), count: 1
    assert_select "[data-controller~=notification-bell][data-notification-bell-unread-value=false]", count: 1
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

  # ---- The history screen (ADR-0052) ----------------------------------------

  # The defect this screen exists for: the bell shows eight and nothing reached
  # the ninth, on the only channel there is while production email is deferred.
  test "the screen reaches a notification the bell cannot show" do
    reader = users(:one)
    ninth = nil
    (Notification::RECENT + 1).times do |index|
      note = Notification.notify(reader, "enrolled", label: "BA-#{index}")
      ninth ||= note
    end
    sign_in_as reader

    get notifications_url

    assert_response :success
    assert_select "[data-notification-id=?]", ninth.id.to_s, { count: 1 },
      "the oldest row is exactly the one the bell could not reach"
  end

  test "the screen pages like every other list that grows" do
    reader = users(:one)
    (Page::SIZE + 4).times { |index| Notification.notify(reader, "enrolled", label: "BA-#{index}") }
    sign_in_as reader

    get notifications_url
    assert_select "[data-notification-id]", Page::SIZE

    get notifications_url(page: 2)
    assert_select "[data-notification-id]", 4
  end

  # ADR-0052 decision 3. A dot that clears by being looked at means "you have not
  # visited" rather than "something happened", and would dismiss the seven the
  # reader did not come for.
  test "reading the screen marks nothing read" do
    reader = users(:one)
    Notification.notify(reader, "enrolled", label: "BA-2")
    sign_in_as reader

    assert_no_changes -> { reader.notifications.unread.count } do
      get notifications_url
    end

    # In `main`, not the page: the header carries the bell and its own copy
    # of this button on every screen.
    assert_select "main form[action=?]", read_notifications_path, { count: 1 },
      "the write stays an explicit button, and this screen shows it"
  end

  test "the screen shows only the reader's own notifications" do
    Notification.notify(users(:two), "enrolled", label: "Someone else's")
    sign_in_as users(:one)

    get notifications_url

    assert_response :success
    assert_select "[data-notification-id]", 0
  end

  test "a stranger is sent to sign in rather than shown a history" do
    get notifications_url

    assert_redirected_to root_path
  end

  # Decision 4: the panel keeps its eight and gains the route past them.
  test "the bell links to the screen" do
    sign_in_as users(:one)

    get root_url

    assert_select "a[href=?]", notifications_path, text: I18n.t("chrome.notif_see_all")
  end

  private
    def make_event(user)
      ProctorEvent.create!(user:, course: Course.find_by!(code: "AI1101"),
                           topic: Topic.find_by!(key: "1-1"), kind: "blur", occurred_at: Time.current)
    end
end
