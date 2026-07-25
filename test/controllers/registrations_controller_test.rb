require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "shows the sign-up form" do
    get register_url
    assert_response :success
  end

  test "creates a user and signs them in" do
    assert_difference "User.count", 1 do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: " 2011071730009 ",
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }
    end

    assert_redirected_to root_url
    assert_equal "2011071730009", User.last.student_id, "the ID is stored, stripped"
    assert_nil User.last.email_address, "sign-up collects no email address"

    # Session cookie is set, so an authenticated-only page is reachable.
    assert cookies[:session_id].present?
  end

  # Sign-up may only ever produce a student — a role is granted from /admin and
  # nowhere else. `user_params` does not permit :role, so a posted one is dropped
  # and the column default applies. This test is what keeps it that way.
  test "a role posted with the sign-up form is ignored" do
    User::ROLES.each_with_index do |role, index|
      post register_url, params: { terms: "1", user: {
        name: "ผู้แอบอ้าง",
        role: role,
        student_id: "201107173002#{index}",
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }

      assert_equal("student", User.last.role, "posting role=#{role} must still create a student")
      assert_not_predicate(User.last, :staff?)
      sign_out
    end
  end

  test "rejects a sign-up that has not accepted the terms" do
    assert_no_difference "User.count" do
      post register_url, params: { user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730010",
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }
    end

    assert_response :unprocessable_entity
    assert_match I18n.t("auth.terms_required"), response.body
  end

  test "rejects a student ID that is not 13 digits" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "24107173",
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert] li", /#{I18n.t("activerecord.errors.models.user.attributes.student_id.invalid")}/
    assert_select "input[name=?][aria-invalid=true]", "user[student_id]"
  end

  test "rejects a blank student ID" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "",
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a mismatched password confirmation" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730011",
        password: "secret-password1",
        password_confirmation: "different-password"
      } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a short password" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730012",
        password: "short",
        password_confirmation: "short"
      } }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a password with no digit in it" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730014",
        password: "onlyletters",
        password_confirmation: "onlyletters"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert] li",
      /#{I18n.t("activerecord.errors.models.user.attributes.password.missing_digit")}/
    assert_select "input[name=?][aria-invalid=true]", "user[password]"
  end

  test "rejects a password everyone guesses first" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730015",
        password: "password123",
        password_confirmation: "password123"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert] li",
      /#{I18n.t("activerecord.errors.models.user.attributes.password.too_common")}/
  end

  test "rejects a password containing the student ID" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "นักศึกษาใหม่",
        student_id: "2011071730016",
        password: "a2011071730016",
        password_confirmation: "a2011071730016"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "div[role=alert] li",
      /#{I18n.t("activerecord.errors.models.user.attributes.password.contains_student_id")}/
  end

  test "rejects a student ID that already has an account" do
    assert_no_difference "User.count" do
      post register_url, params: { terms: "1", user: {
        name: "ซ้ำ",
        student_id: users(:student).student_id,
        password: "secret-password1",
        password_confirmation: "secret-password1"
      } }
    end

    assert_response :unprocessable_entity
  end
end
