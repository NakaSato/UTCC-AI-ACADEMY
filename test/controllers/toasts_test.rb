require "test_helper"

# The toast host is chrome: it ships with the application layout on every screen
# rather than being rendered by whichever view happens to need it, so a
# controller can raise a message from anywhere without the page opting in.
#
# What is asserted here is the contract toast_controller.js depends on — the
# host, its two targets, and the action that routes `toast:show` — because a
# renamed target breaks the JS silently, with nothing failing server-side.
class ToastsTest < ActionDispatch::IntegrationTest
  test "the toast host ships on a signed-in screen" do
    sign_in_as users(:one)

    get progress_path

    assert_response :success
    assert_toast_host
  end

  test "the toast host ships on the landing page" do
    get root_path

    assert_response :success
    assert_toast_host
  end

  test "the auth screens carry no toast host" do
    # A different layout, and nothing on it dispatches yet — asserted so that
    # adding a caller there is a deliberate change rather than a surprise.
    get login_path

    assert_response :success
    assert_select "[data-controller=toast]", 0
  end

  test "one host per page, so a message cannot render twice" do
    sign_in_as users(:one)

    get my_learning_path

    assert_response :success
    assert_select "[data-controller=toast]", 1
  end

  # The host had no callers for a while: it shipped on every screen and never
  # showed anything. The first two are the lesson's grading failures — the one
  # case with no other surface, since a refusal brings no page load and so no
  # flash. Asserted here for the same reason as the targets above: the copy is
  # read out of the DOM by name, so a renamed attribute fails silently.
  test "the lesson carries the copy its toasts are raised with" do
    sign_in_as users(:one)

    get lesson_path

    assert_response :success
    assert_select "template[data-quiz-target=copy][data-unreachable=?]",
                  I18n.t("lesson.grading_unreachable")
    assert_select "template[data-code-task-target=copy][data-unreachable=?]",
                  I18n.t("lesson.grading_unreachable")
  end

  # A pass deliberately raises no toast: the exercise writes its verdict into the
  # feedback panel and the coding task into the console, both of which stay on
  # screen. Toasting it too would say the same thing twice and then take it away.
  test "a graded verdict has its own surface, so nothing toasts it" do
    sign_in_as users(:one)

    get lesson_path

    assert_response :success
    assert_select "[data-quiz-target=feedback]"
    assert_select "[data-code-task-target=console]"
  end

  # Urgency is a screen-reader concern, not a styling one: an error interrupts
  # and a confirmation waits its turn. Two regions is how that is said, and the
  # controller files a row into one of them by kind, so both have to be here.
  test "the host carries a polite and an assertive region" do
    get root_path

    assert_select "#toasts [data-toast-target=list][data-urgency=polite][aria-live=polite][role=status]", 1
    assert_select "#toasts [data-toast-target=list][data-urgency=assertive][aria-live=assertive][role=alert]", 1
  end

  # Everything below is read out of the DOM by name at runtime, so a renamed
  # slot breaks a toast silently with nothing failing server-side.
  test "the row template carries every slot a caller can fill" do
    get root_path

    assert_select "template[data-toast-target=row] [data-toast-row]", 1
    %w[title message action close].each do |slot|
      assert_select "template[data-toast-target=row]", html: /data-slot="#{slot}"/,
                    count: 1, message: "the row template has no #{slot} slot"
    end
  end

  test "the row can be dismissed by the person reading it, in their language" do
    get root_path

    assert_select "template[data-toast-target=row]",
                  html: /#{Regexp.escape(I18n.t("chrome.toast_dismiss", locale: :th))}/
  end

  private
    def assert_toast_host
      # The id is what `turbo_stream.toast` names as its target — see
      # test/helpers/toast_stream_test.rb for the tag that names it. The anchor
      # is what tells the controller whether there is a header to clear.
      assert_select "#toasts[data-controller=toast][data-toast-anchor-value=top]" \
                    "[data-action='toast:show@window->toast#show']", 1
      assert_select "[data-controller=toast] [data-toast-target=list]", 2
      assert_select "[data-controller=toast] template[data-toast-target=row]", 1
    end
end
