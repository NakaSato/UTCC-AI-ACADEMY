require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  # Password reset needs an account that actually has an email address; sign-up
  # collects none, so only some do.
  setup { @user = users(:one) }

  test "new" do
    get forgot_password_path
    assert_response :success
  end

  test "create" do
    post forgot_password_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to forgot_password_path(sent: 1)

    follow_redirect!
    assert_select "[role=status]", /#{I18n.t("auth.forgot.sent_title")}/
  end

  test "create for an unknown user says the same thing but sends no mail" do
    post forgot_password_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to forgot_password_path(sent: 1)

    follow_redirect!
    assert_select "[role=status]", /#{I18n.t("auth.forgot.sent_title")}/
  end

  # Without the presence check in the controller this would look up
  # email_address IS NULL and mail one of the accounts that has no address.
  test "create with a blank address matches no account" do
    assert_predicate users(:two).email_address, :blank?, "fixture must have no address"

    post forgot_password_path, params: { email_address: "" }
    assert_enqueued_emails 0
    assert_redirected_to forgot_password_path(sent: 1)
  end

  test "new without the sent flag shows no confirmation" do
    get forgot_password_path
    assert_select "[role=status]", false
  end

  test "edit" do
    get reset_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get reset_password_path("invalid token")
    assert_redirected_to forgot_password_path

    follow_redirect!
    assert_notice "ลิงก์ตั้งรหัสผ่านไม่ถูกต้อง"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put reset_password_path(@user.password_reset_token),
          params: { password: "new-password1", password_confirmation: "new-password1" }
      assert_redirected_to login_path
    end

    follow_redirect!
    assert_notice "ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว"
  end

  test "update rejects a password below the minimum length" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put reset_password_path(token), params: { password: "short", password_confirmation: "short" }
      assert_redirected_to reset_password_path(token)
    end
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put reset_password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to reset_password_path(token)
    end

    follow_redirect!
    assert_notice "รหัสผ่านไม่ตรงกัน"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
