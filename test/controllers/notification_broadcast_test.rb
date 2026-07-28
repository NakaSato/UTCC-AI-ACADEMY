require "test_helper"
require "turbo/broadcastable/test_helper"

# The browser end of the bell: that a signed-in page subscribes, that an admin
# acting on a student reaches that student's page, and — the half the broadcast
# exists to make possible — that the bell the browser fetches back is one the
# reader can actually read and use.
class NotificationBroadcastTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  FRAME = NotificationBell::ID

  setup { sign_in_as users(:one) }

  test "a signed-in screen subscribes the bell" do
    get root_url

    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name=?]",
      Turbo::StreamsChannel.signed_stream_name(NotificationBell.new(users(:one)).stream)
  end

  # The frame a request renders must not name a source, or every screen in the app
  # fetches the bell a second time on load.
  test "the bell a page renders does not refetch itself" do
    get root_url

    assert_select "turbo-frame##{FRAME}"
    assert_select "turbo-frame##{FRAME}[src]", count: 0
  end

  test "a signed-out page subscribes nothing" do
    sign_out
    get root_url

    assert_response :success
    assert_select "turbo-cable-stream-source", count: 0
  end

  # End to end through the endpoint rather than the model: an admin acting on a
  # case reaches the student's bell.
  test "an admin notifying a student reaches that student's bell" do
    student = users(:student)
    # A case is a learner's unreviewed proctor events, so there has to be one.
    ProctorEvent.create!(user: student, course: courses(:ai1101), topic: topics(:topic_1_1),
                         kind: "blur", occurred_at: Time.current)
    sign_in_as users(:admin)

    assert_turbo_stream_broadcasts NotificationBell.new(student).stream, count: 1 do
      post notify_integrity_case_url(student)
    end
  end

  test "marking everything read pushes to the reader's other tabs" do
    Notification.notify(users(:one), "enrolled", label: "BA-2")

    assert_turbo_stream_broadcasts NotificationBell.new(users(:one)).stream, count: 1 do
      post read_notifications_url
    end
  end

  test "the refetched bell is the bell, and brings no chrome with it" do
    Notification.notify(users(:one), "enrolled", label: "BA-2")

    get notifications_url, headers: { "Turbo-Frame" => FRAME }

    assert_response :success
    assert_select "turbo-frame##{FRAME}[src]", count: 0, message: "or it fetches itself forever"
    assert_select "turbo-frame##{FRAME} [data-controller=dropdown]"
    assert_select "header", count: 0
  end

  # The reason the broadcast pushes a frame instead of the bell. This request has
  # the reader's session, so the copy is in the language they chose — even when
  # somebody else in another language caused the notification.
  test "the refetched bell is in the reader's language, not the actor's" do
    post language_path(:en)
    I18n.with_locale(:th) { Notification.notify(users(:one), "enrolled", label: "BA-2") }

    get notifications_url, headers: { "Turbo-Frame" => FRAME }

    assert_select "turbo-frame##{FRAME}", text: /#{I18n.t("notifications.enrolled", label: "BA-2", locale: :en)}/
    assert_select "turbo-frame##{FRAME}", { text: /#{I18n.t("chrome.notif_title", locale: :th)}/, count: 0 }
  end

  test "the bell is not something a stranger can read" do
    sign_out
    get notifications_url

    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  # The other reason. The panel carries the one form this menu has, and a form
  # rendered without a session gets no token — so the refetched bell has to be the
  # thing that supplies one. Forgery protection is off in the test environment, so
  # this turns it on for the length of the exchange, the way
  # sessions_controller_test lends the rate limiter a real cache store.
  test "the refetched bell's mark-all-read button is one the reader can submit" do
    Notification.notify(users(:one), "enrolled", label: "BA-2")

    with_forgery_protection do
      get notifications_url, headers: { "Turbo-Frame" => FRAME }
      token = css_select("input[name=authenticity_token]").first&.[]("value")

      assert_not_nil token, "the refetched bell has to carry a token at all"

      post read_notifications_url, params: { authenticity_token: token }
    end

    assert_response :redirect
    assert_empty users(:one).notifications.unread,
      "the token the bell shipped was refused, so the click did nothing"
  end

  private
    def with_forgery_protection
      was = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      yield
    ensure
      ActionController::Base.allow_forgery_protection = was
    end
end
