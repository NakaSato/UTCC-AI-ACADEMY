require "test_helper"

# The other half of a one-time first password. A console account has no student
# ID and may never reach the email reset, so when the password is gone an
# administrator is the only way back in — and that is deliberately not true of a
# learner, who resets their own by email without an admin reading the new one.
class AdminPasswordReissueTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @instructor = users(:console_instructor)
  end

  def reissue(user)
    post admin_user_password_path(user)
  end

  def password_from_flash = flash[:notice][/\b[a-z][A-Za-z0-9]{10}\d\b/]

  test "the button is offered for console accounts and not for learners" do
    get admin_url(tab: :users)

    assert_response :success
    assert_select "form[action=?]", admin_user_password_path(@instructor)
    assert_select "form[action=?]", admin_user_password_path(users(:student)), false
  end

  test "a reissued password signs the account in and the old one stops working" do
    reissue @instructor

    password = password_from_flash
    assert_not_nil password, "the flash should carry the new password"
    assert_equal @instructor, User.authenticate_by(username: @instructor.username, password:)
    assert_nil User.authenticate_by(username: @instructor.username, password: "password")
  end

  # A forgotten password may be a stolen one. Ending the sessions is what makes
  # this a recovery rather than a second key.
  test "reissuing signs that account out everywhere" do
    session = @instructor.sessions.create!

    reissue @instructor

    assert_not Session.exists?(session.id)
    assert_predicate @instructor.sessions.reload, :empty?
  end

  test "a company account is eligible" do
    organization = Organization.create!(name: "Console Co", creator: users(:admin))
    organization.memberships.create!(user: users(:console_company), role: "recruiter")

    reissue users(:console_company)

    assert_not_nil password_from_flash
  end

  # /forgot-password is theirs, and it reaches them without an administrator
  # reading their new password.
  test "a learner is refused" do
    student = users(:student)
    digest = student.password_digest

    reissue student

    assert_equal I18n.t("flash.password_reissue_not_console"), flash[:alert]
    assert_equal digest, student.reload.password_digest
  end

  test "an admin cannot reissue their own" do
    digest = users(:admin).password_digest

    reissue users(:admin)

    assert_equal I18n.t("flash.password_reissue_self"), flash[:alert]
    assert_equal digest, users(:admin).reload.password_digest
  end

  test "the reissue is audited as a privilege change and omits the password" do
    assert_difference "AuditEvent.count", 1 do
      reissue @instructor
    end

    event = AuditEvent.order(:id).last
    assert_equal "console_password_reissued", event.action
    assert_equal :warn, event.level
    assert_match @instructor.username, event.text
    assert_not_includes event.params.to_s, password_from_flash
  end

  test "a non-admin cannot reissue a password" do
    sign_out
    sign_in_as users(:instructor)
    digest = @instructor.password_digest

    reissue @instructor

    assert_redirected_to root_path
    assert_equal digest, @instructor.reload.password_digest
  end
end
