require "test_helper"

# The signed-in chrome branches on the role in two places: the nav list, and the
# gamification strip below it. A new file rather than an addition to
# app_screens_test.rb, which asserts what a screen renders rather than what the
# header wraps it in.
class AppHeaderTest < ActionDispatch::IntegrationTest
  HEARTS = -> { I18n.t("chrome.hearts_left", count: 5, max: 5) }

  test "a student at full hearts sees the counter and no refill timer" do
    sign_in_as users(:one)
    get root_url

    assert_response :success
    assert_includes response.body, HEARTS.call
    assert_not_includes response.body, I18n.t("chrome.refill", hours: 3, minutes: 59).split(" ").last,
                        "a full set of hearts has nothing to count down to"
  end

  test "a fresh failure costs a heart and starts the countdown" do
    student = users(:one)
    # Mid-minute on purpose: the view ceils the remaining time, and a failure
    # created "now" sits exactly on the 4h boundary.
    at = 2.hours.ago + 45.seconds
    Submission.create!(user: student, course: Course.find_by!(code: "AI1101"),
                       topic: Topic.find_by!(key: "1-1"), kind: "quiz", answer: "3", passed: false,
                       created_at: at, updated_at: at)

    sign_in_as student
    get root_url

    assert_includes response.body, I18n.t("chrome.hearts_left", count: 4, max: 5)
    assert_includes response.body, I18n.t("chrome.refill", hours: 2, minutes: 1)
  end

  # Hearts count lives nobody has on a staff screen, so staff are left out of
  # the mechanic the way proctor_controller leaves them out of the proctor.
  test "an instructor gets the strip without the hearts" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_response :success
    assert_not_includes response.body, HEARTS.call
    assert_includes response.body, I18n.t("chrome.semester")
  end

  test "an admin gets the strip without the hearts" do
    sign_in_as users(:admin)
    get admin_url

    assert_response :success
    assert_not_includes response.body, HEARTS.call
    assert_includes response.body, I18n.t("chrome.semester")
  end

  # The semester is the strip's only remaining content for staff, so it must not
  # keep the `lg:inline` that hides it beside a counter it no longer sits next to.
  test "the semester stops hiding itself once the counters are gone" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_select "header span", text: /#{Regexp.escape(I18n.t("chrome.semester"))}/ do |spans|
      assert_no_match(/\blg:inline\b/, spans.first[:class].to_s)
    end
  end

  test "a student keeps the semester tucked away on narrow screens" do
    sign_in_as users(:one)
    get root_url

    assert_select "header span", text: /#{Regexp.escape(I18n.t("chrome.semester"))}/ do |spans|
      assert_match(/\blg:inline\b/, spans.first[:class].to_s)
    end
  end
end
