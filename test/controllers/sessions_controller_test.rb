require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:student) }

  test "new" do
    get login_path
    assert_response :success
  end

  test "create with valid credentials" do
    post login_path, params: { student_id: @user.student_id, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  # One sign-in screen for everyone: authentication is role-agnostic, and what a
  # role changes is only which screens open afterwards.
  test "every role signs in through the same form" do
    [ users(:student), users(:instructor), users(:admin) ].each do |user|
      post login_path, params: { student_id: user.student_id, password: "password" }

      assert_redirected_to root_path, "#{user.role} should be able to sign in"
      assert(cookies[:session_id].present?, "#{user.role} should get a session")

      delete logout_path
    end
  end

  test "create with invalid credentials" do
    post login_path, params: { student_id: @user.student_id, password: "wrong" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "create with an email address in the student ID field" do
    post login_path, params: { student_id: users(:one).email_address, password: "password" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "create with a blank student ID" do
    post login_path, params: { student_id: "", password: "password" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete logout_path

    assert_redirected_to login_path
    assert_empty cookies[:session_id]
  end
end
