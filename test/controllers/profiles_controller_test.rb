require "test_helper"

# The account's own details. Sign-up asks for a name, a student ID and a
# password, so this screen is the only way the rest of the columns are ever
# filled in — and the only way an account gets the email address password reset
# needs. Fixture `two` deliberately has none, which is what most accounts look
# like.
class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:two) }

  test "shows the form filled in with the current details" do
    get profile_url

    assert_response :success
    assert_select "main h1", text: I18n.t("profile.title")
    assert_select "input[name=?][value=?]", "user[name]", users(:two).name
  end

  # The point of the whole screen: an account that had no address ends up with
  # one, so PasswordsController#create can find it.
  test "adds an email address to an account that had none" do
    assert_nil users(:two).email_address

    patch profile_url, params: { user: { email_address: " Two@UTCC.ac.th " } }

    assert_redirected_to profile_url
    assert_equal I18n.t("flash.profile_saved"), flash[:notice]
    assert_equal "two@utcc.ac.th", users(:two).reload.email_address, "stripped and downcased"
  end

  test "the saved address is what password reset then finds" do
    patch profile_url, params: { user: { email_address: "two@utcc.ac.th" } }
    sign_out

    assert_enqueued_emails 1 do
      post forgot_password_path, params: { email_address: "two@utcc.ac.th" }
    end
  end

  # A cleared address has to land as NULL, not "". The column is uniquely
  # indexed and the uniqueness validation is `allow_blank`, so two accounts
  # storing "" would raise RecordNotUnique from the database rather than fail
  # validation. User's normalizer is what prevents it.
  test "clearing the email address stores NULL rather than an empty string" do
    patch profile_url, params: { user: { email_address: "  " } }
    assert_nil users(:two).reload.email_address

    sign_out
    sign_in_as users(:one)
    patch profile_url, params: { user: { email_address: "" } }

    assert_redirected_to profile_url
    assert_nil users(:one).reload.email_address
  end

  test "saves faculty and year of study, and clears them again" do
    patch profile_url, params: { user: { faculty: " บริหารธุรกิจ ", study_year: "3" } }

    assert_equal "บริหารธุรกิจ", users(:two).reload.faculty
    assert_equal 3, users(:two).study_year

    patch profile_url, params: { user: { faculty: "", study_year: "" } }

    assert_nil users(:two).reload.faculty, "blank faculty is NULL, not an empty string"
    assert_nil users(:two).study_year
  end

  test "an invalid address re-renders the form and changes nothing" do
    patch profile_url, params: { user: { name: "ชื่อใหม่", email_address: "not-an-email" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_equal users(:two).name, users(:two).reload.name, "nothing is saved when one field fails"
  end

  test "an address already on another account is rejected" do
    patch profile_url, params: { user: { email_address: users(:one).email_address } }

    assert_response :unprocessable_entity
    assert_nil users(:two).reload.email_address
  end

  test "a blank name is rejected" do
    patch profile_url, params: { user: { name: "  " } }

    assert_response :unprocessable_entity
    assert_predicate users(:two).reload.name, :present?
  end

  test "an out-of-range year of study is rejected" do
    patch profile_url, params: { user: { study_year: "99" } }

    assert_response :unprocessable_entity
    assert_nil users(:two).reload.study_year
  end

  # The student ID is the sign-in identifier, the roster's key and what every
  # completion is read against. It is absent from profile_params, so a posted
  # one is dropped — the same guarantee registrations_controller_test.rb makes
  # about :role.
  test "a student ID posted with the form is ignored" do
    original = users(:two).student_id

    patch profile_url, params: { user: { name: "ชื่อใหม่", student_id: "9999999999999" } }

    assert_redirected_to profile_url
    assert_equal original, users(:two).reload.student_id
    assert_equal "ชื่อใหม่", users(:two).name, "the permitted field still saved"
  end

  # Same rule as sign-up: /admin is the only place a role is granted.
  test "a role posted with the form is ignored" do
    User::ROLES.each do |role|
      patch profile_url, params: { user: { role: role } }

      assert_equal "student", users(:two).reload.role, "posting role=#{role} must not grant it"
    end
  end

  # Current.user, not a user named in the URL — there is no id in the path, so
  # there is nothing to tamper with. This pins that the action edits the signed-in
  # account and no other.
  test "the form edits the signed-in account" do
    patch profile_url, params: { user: { name: "แก้เฉพาะของตัวเอง" } }

    assert_equal "แก้เฉพาะของตัวเอง", users(:two).reload.name
    assert_equal "นักศึกษา หนึ่ง", users(:one).reload.name
  end

  test "both verbs require a session" do
    sign_out

    get profile_url
    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]

    patch profile_url, params: { user: { name: "ไม่ควรบันทึก" } }
    assert_redirected_to root_path
  end

  # ---- Changing the password ---------------------------------------------
  # /reset-password is the signed-out way in and needs mail that is not
  # configured. This is the signed-in one and needs nothing, which is the whole
  # point of it existing.

  test "changes the password when the current one is right" do
    patch profile_password_url, params: {
      current_password: "password",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_redirected_to profile_url
    assert_equal I18n.t("flash.password_changed"), flash[:notice]
    assert users(:two).reload.authenticate("brand-new-password9"), "the new password works"
    assert_not users(:two).authenticate("password"), "the old one does not"
  end

  test "the new password is what signs in afterwards" do
    patch profile_password_url, params: {
      current_password: "password",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }
    sign_out

    post login_path, params: { student_id: users(:two).student_id, password: "password" }
    assert_redirected_to login_path, "the old password is refused"

    post login_path, params: { student_id: users(:two).student_id, password: "brand-new-password9" }
    assert_redirected_to root_url
  end

  # The session cookie alone should not be enough to change the password it
  # protects — a borrowed laptop is the case this is for.
  test "a wrong current password changes nothing" do
    patch profile_password_url, params: {
      current_password: "not-my-password1",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_response :unprocessable_entity
    assert users(:two).reload.authenticate("password"), "the password is untouched"
    assert_select "div[role=alert]"
  end

  test "a blank current password changes nothing" do
    patch profile_password_url, params: {
      current_password: "",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_response :unprocessable_entity
    assert users(:two).reload.authenticate("password")
  end

  # User's own rules apply — this is an ordinary update, not a special path
  # around them.
  test "a weak new password is rejected" do
    [ "short1", "password", "12345678", "onlyletters" ].each do |weak|
      patch profile_password_url, params: {
        current_password: "password", password: weak, password_confirmation: weak
      }

      assert_response :unprocessable_entity, "#{weak.inspect} should be refused"
      assert users(:two).reload.authenticate("password"), "#{weak.inspect} must not have been saved"
    end
  end

  test "a mismatched confirmation is rejected" do
    patch profile_password_url, params: {
      current_password: "password",
      password: "brand-new-password9",
      password_confirmation: "something-else9"
    }

    assert_response :unprocessable_entity
    assert users(:two).reload.authenticate("password")
  end

  # Two forms, one record. A rejected password must not report itself above the
  # name and email fields, and vice versa.
  test "errors are shown on the form that was submitted" do
    patch profile_password_url, params: {
      current_password: "wrong-password1", password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_response :unprocessable_entity
    assert_select "form[action=?] div[role=alert]", profile_password_path, count: 1
    assert_select "form[action=?] div[role=alert]", profile_path, count: 0

    patch profile_url, params: { user: { email_address: "not-an-email" } }

    assert_response :unprocessable_entity
    assert_select "form[action=?] div[role=alert]", profile_path, count: 1
    assert_select "form[action=?] div[role=alert]", profile_password_path, count: 0
  end

  # Everywhere else is now signed in with a password its holder replaced. This
  # device is spared: being made to sign in again on the machine you just used
  # reads as a failure rather than as security.
  test "changing the password signs out other devices but not this one" do
    other = users(:two).sessions.create!(user_agent: "elsewhere", ip_address: "10.0.0.9")

    patch profile_password_url, params: {
      current_password: "password",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_not Session.exists?(other.id), "the other session is gone"
    assert_equal 1, users(:two).sessions.count

    # Still signed in here: the next request does not bounce to the landing page.
    get profile_url
    assert_response :success
  end

  test "a failed change leaves other sessions alone" do
    other = users(:two).sessions.create!(user_agent: "elsewhere", ip_address: "10.0.0.9")

    patch profile_password_url, params: {
      current_password: "wrong-password1",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_response :unprocessable_entity
    assert Session.exists?(other.id), "a refused attempt must not sign anyone out"
  end

  test "changing a password requires a session" do
    sign_out

    patch profile_password_url, params: {
      current_password: "password",
      password: "brand-new-password9",
      password_confirmation: "brand-new-password9"
    }

    assert_redirected_to root_path
    assert users(:two).reload.authenticate("password")
  end
end
