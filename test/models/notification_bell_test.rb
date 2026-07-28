require "test_helper"
# turbo-rails auto-includes this into ActiveSupport::TestCase only once Action
# Cable has been loaded, and until this seam existed nothing in the app loaded it.
require "turbo/broadcastable/test_helper"

# The bell getting itself redrawn. Notifications are written *for* somebody by
# somebody else, so every assertion here is about a page nobody is looking at
# learning something it never asked for.
class NotificationBellTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @user = users(:one)
    @bell = NotificationBell.new(@user)
  end

  test "creating a notification broadcasts to its recipient" do
    assert_turbo_stream_broadcasts @bell.stream, count: 1 do
      Notification.notify(@user, "enrolled", label: "BA-2")
    end
  end

  test "nobody else's bell hears about it" do
    assert_no_turbo_stream_broadcasts NotificationBell.new(users(:two)).stream do
      Notification.notify(@user, "enrolled", label: "BA-2")
    end
  end

  test "the broadcast replaces the bell by the id the bell owns" do
    Notification.notify(@user, "enrolled", label: "BA-2")

    assert_equal "replace", pushed["action"]
    assert_equal NotificationBell::ID, pushed["target"]
    assert_equal NotificationBell::ID, pushed.at_css("turbo-frame")["id"]
  end

  # The load-bearing one. What goes over the wire is a frame that names a source,
  # never the bell: a broadcast has no session, so anything it rendered would
  # carry no CSRF token for the panel's form and would be written in the language
  # of whoever *triggered* it. Both failures look completely normal on screen.
  test "the broadcast carries no rendered bell, only somewhere to fetch one" do
    Notification.notify(@user, "enrolled", label: "BA-2")

    frame = pushed.at_css("turbo-frame")
    html = pushed.to_html

    assert_equal "/notifications", frame["src"]
    assert_no_match(/authenticity_token/, html, "a token minted without a session is one nobody can submit")
    I18n.available_locales.each do |locale|
      assert_not_includes html, I18n.t("chrome.notif_title", locale: locale),
        "no copy may cross the wire — the reader's language is not knowable here"
      assert_not_includes html, I18n.t("notifications.enrolled", label: "BA-2", locale: locale)
    end
  end

  # Without it the frame is empty for the length of the fetch and the header's
  # whole right-hand rail slides sideways.
  test "the pushed frame holds the bell's place while it refetches" do
    Notification.notify(@user, "enrolled", label: "BA-2")

    placeholder = pushed.at_css("turbo-frame span")

    assert_not_nil placeholder, "an empty frame collapses and the header jumps"
    assert_includes placeholder["class"], "size-[38px]"
    assert_includes placeholder["class"], "skeleton-on-chrome", "the header is the chrome field"
  end

  test "the dot survives a notification falling off the bottom of the panel" do
    (Notification::RECENT + 1).times { Notification.notify(@user, "enrolled", label: "BA-2") }
    @user.notifications.newest_first.limit(Notification::RECENT).update_all(read_at: Time.current)

    bell = NotificationBell.new(@user.reload)

    assert_equal Notification::RECENT, bell.recent.size
    assert_predicate bell, :unread?, "the unread row is older than the panel is long, and still unread"
  end

  test "recent is newest first and capped" do
    3.times { |index| Notification.notify(@user, "enrolled", label: "S#{index}") }

    assert_equal %w[ S2 S1 S0 ], NotificationBell.new(@user).recent.map { it.params["label"] }
  end

  private
    def pushed = capture_turbo_stream_broadcasts(@bell.stream).sole
end
