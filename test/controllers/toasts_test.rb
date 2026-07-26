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

  private
    def assert_toast_host
      assert_select "[data-controller=toast][data-action='toast:show@window->toast#show']", 1
      assert_select "[data-controller=toast] [data-toast-target=list]", 1
      assert_select "[data-controller=toast] template[data-toast-target=row]", 1
    end
end
