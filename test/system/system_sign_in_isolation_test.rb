require "application_system_test_case"

# Regression evidence for the Edge session leak seen only in the full system
# suite. A stale protected destination must not decide where the next test's
# explicit real-form sign-in lands.
class SystemSignInIsolationTest < ApplicationSystemTestCase
  test "real-form sign-in starts from a clean browser session" do
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    assert_current_path root_path

    sign_in_through_the_form users(:one)

    assert_current_path root_path
  end
end
