require "test_helper"

# The signed-in chrome branches on the role in two places: the nav list, and the
# gamification strip below it. A new file rather than an addition to
# app_screens_test.rb, which asserts what a screen renders rather than what the
# header wraps it in.
class AppHeaderTest < ActionDispatch::IntegrationTest
  HEARTS = -> { I18n.t("chrome.hearts_left", count: LearnerProfile::LIVES) }

  test "a student sees the hearts counter and the refill timer" do
    sign_in_as users(:one)
    get root_url

    assert_response :success
    assert_includes response.body, HEARTS.call
    assert_includes response.body, I18n.t("chrome.refill")
  end

  # Hearts count lives nobody has on a staff screen, so staff are left out of
  # the mechanic the way proctor_controller leaves them out of the proctor.
  test "an instructor gets the strip without the hearts" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_response :success
    assert_not_includes response.body, HEARTS.call
    assert_not_includes response.body, I18n.t("chrome.refill")
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
