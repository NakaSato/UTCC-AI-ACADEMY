require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "shows the sign-up form" do
    get new_registration_url
    assert_response :success
  end

  test "creates a user and signs them in" do
    assert_difference "User.count", 1 do
      post registration_url, params: { user: {
        name: "นักศึกษาใหม่",
        email_address: "New.Student@utcc.ac.th",
        password: "secret-password",
        password_confirmation: "secret-password",
        faculty: "วิศวกรรมศาสตร์",
        study_year: 1
      } }
    end

    assert_redirected_to root_url
    assert_equal "new.student@utcc.ac.th", User.last.email_address, "email should be normalized"

    # Session cookie is set, so an authenticated-only page is reachable.
    assert cookies[:session_id].present?
  end

  test "rejects a mismatched password confirmation" do
    assert_no_difference "User.count" do
      post registration_url, params: { user: {
        name: "นักศึกษาใหม่",
        email_address: "mismatch@utcc.ac.th",
        password: "secret-password",
        password_confirmation: "different-password"
      } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a short password" do
    assert_no_difference "User.count" do
      post registration_url, params: { user: {
        name: "นักศึกษาใหม่",
        email_address: "short@utcc.ac.th",
        password: "short",
        password_confirmation: "short"
      } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a duplicate email address regardless of case" do
    assert_no_difference "User.count" do
      post registration_url, params: { user: {
        name: "ซ้ำ",
        email_address: "ONE@example.com",
        password: "secret-password",
        password_confirmation: "secret-password"
      } }
    end

    assert_response :unprocessable_entity
  end
end
