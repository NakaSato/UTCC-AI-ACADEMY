require "application_system_test_case"

# Clearing the bell used to navigate: the redirect was there only so the bell
# would be redrawn and so something would say it had worked. It answers a Turbo
# request with a stream now, and only a browser can tell whether that lands —
# the form sits inside a <turbo-frame>, and a frame that is handed a stream
# instead of a frame is the shape that writes "Content missing" where the bell
# was. Hence a system test.
#
# It also covers the toast host end to end for the first time: a real caller,
# a real stream, a real row.
class NotificationBellWalkTest < ApplicationSystemTestCase
  test "marking the bell read redraws it and toasts, without leaving the page" do
    student = users(:one)
    # Written through the one writer, as notifications.yml asks.
    Notification.notify(student, :enrolled, label: sections(:ba_2).label)

    sign_in_through_the_form(student)
    visit "/progress"
    assert_selector "##{NotificationBell::ID} button"

    # The dot is the unread count's existence — see the bell partial.
    assert_selector "##{NotificationBell::ID} .bg-brand.rounded-full"

    find("##{NotificationBell::ID} [data-dropdown-target=button]").click
    click_button I18n.t("chrome.notif_read_all", locale: :th)

    # The toast is the whole point: feedback without a page load.
    assert_selector "#toasts [data-kind=success]",
                    text: I18n.t("flash.notifications_read", locale: :th)
    assert_current_path "/progress"

    # And the bell came back cleared in the same response. Action Cable's test
    # adapter delivers nothing here, so this can only be the stream — which is
    # exactly the tab the broadcast was never going to answer in time anyway.
    assert_no_selector "##{NotificationBell::ID} .bg-brand.rounded-full"
    assert_equal 0, student.notifications.unread.count
  end

  # Nothing raises four at once on purpose, but the lesson's grading failures can
  # arrive in a flurry, and a stack tall enough to cover the page is worse than
  # the messages are useful. Driven by hand for the same reason the frame
  # recovery test drives its frame by hand: what triggers a burst in production
  # cannot be arranged in a test.
  test "a burst of toasts is capped, oldest first" do
    sign_in_through_the_form(users(:one))

    stream = 5.times.map do |index|
      %(<turbo-stream kind="info" duration="0" action="toast" target="toasts">) +
        %(<template>Message #{index}</template></turbo-stream>)
    end.join

    execute_script("window.Turbo.renderStreamMessage(arguments[0])", stream)

    assert_selector "#toasts [data-kind]", count: 3
    # The three that survive are the three most recent; the reader has already
    # had time for the ones dropped.
    assert_no_text "Message 0"
    assert_no_text "Message 1"
    assert_text "Message 4"
  end

  test "a toast can be dismissed before its time is up" do
    student = users(:one)
    Notification.notify(student, :enrolled, label: sections(:ba_2).label)

    sign_in_through_the_form(student)
    find("##{NotificationBell::ID} [data-dropdown-target=button]").click
    click_button I18n.t("chrome.notif_read_all", locale: :th)

    assert_selector "#toasts [data-kind=success]"
    find("#toasts [data-slot=close]").click

    assert_no_selector "#toasts [data-kind=success]"
  end
end
