require "test_helper"

# Sign-up produces learners and an organization invitation only reaches an
# account that already exists, so this form is where an instructor, an
# administrator, or a company member comes from. None of them gets a student ID.
class AdminConsoleAccountsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @organization = Organization.create!(name: "Console Co", creator: users(:admin))
  end

  def create_console_account(access:, **overrides)
    params = { access:,
               console_account: { name: "คอนโซล ใหม่", username: "new-console",
                                  email_address: "new@example.com" }.merge(overrides.delete(:console_account) || {}) }

    post admin_console_accounts_path, params: params.merge(overrides)
  end

  test "the form is on the users tab" do
    get admin_url(tab: :users)

    assert_response :success
    assert_select "form[action=?]", admin_console_accounts_path
    assert_select "input[name=?]", "console_account[username]"
    # No student ID field: that is the whole point of a console account.
    assert_select "input[name=?]", "console_account[student_id]", false
  end

  test "an instructor account is created with no student ID" do
    assert_difference "User.count", 1 do
      create_console_account(access: "instructor")
    end

    user = User.find_by!(username: "new-console")
    assert_predicate user, :instructor?
    assert_nil user.student_id
    assert_predicate user, :console_access?
  end

  test "an admin account is created" do
    create_console_account(access: "admin", console_account: { name: "ผู้ดูแล ใหม่", username: "new-admin",
                                                              email_address: "new-admin@example.com" })

    assert_predicate User.find_by!(username: "new-admin"), :admin?
  end

  # A company account is an ordinary account plus an active membership — the role
  # column stays "student", because company reach is never a role (ADR-0024).
  test "a company account is created with an active membership" do
    assert_difference [ "User.count", "OrganizationMembership.count" ], 1 do
      create_console_account(access: "company", organization_id: @organization.id, membership_role: "recruiter")
    end

    user = User.find_by!(username: "new-console")
    assert_predicate user, :student?
    assert_predicate user, :console_access?
    membership = @organization.memberships.find_by!(user:)
    assert_equal "recruiter", membership.role
    assert_predicate membership, :active?
  end

  test "a company account without an organization creates nothing" do
    assert_no_difference "User.count" do
      create_console_account(access: "company", membership_role: "recruiter")
    end

    assert_equal I18n.t("flash.console_account_no_organization"), flash[:alert]
  end

  # The membership and the account are one write: a role the organization would
  # refuse must not leave an account behind that nobody meant to create.
  test "an invalid membership role rolls the account back" do
    assert_no_difference "User.count" do
      create_console_account(access: "company", organization_id: @organization.id, membership_role: "janitor")
    end
  end

  test "an access level the screen does not grant is refused" do
    assert_no_difference "User.count" do
      create_console_account(access: "student")
    end

    assert_equal I18n.t("flash.console_account_invalid"), flash[:alert]
  end

  # The role comes from the whitelisted `access` param, never from the account
  # attributes — otherwise the form would mint admins by a name it never offered.
  test "a posted role is ignored" do
    create_console_account(access: "instructor",
                           console_account: { name: "แอบ", username: "sneaky",
                                              email_address: "sneaky@example.com", role: "admin" })

    assert_predicate User.find_by!(username: "sneaky"), :instructor?
  end

  test "an account with neither username nor email is refused" do
    assert_no_difference "User.count" do
      create_console_account(access: "instructor",
                             console_account: { name: "ไร้ชื่อเรียก", username: "", email_address: "" })
    end
  end

  test "a duplicate username is refused" do
    assert_no_difference "User.count" do
      create_console_account(access: "instructor",
                             console_account: { name: "ซ้ำ", username: users(:console_instructor).username,
                                                email_address: "dupe@example.com" })
    end
  end

  # Shown once, in a flash, and never stored in the clear — the admin relays it
  # and the account owner changes it on their profile.
  test "the first password is generated, shown once, and works" do
    create_console_account(access: "instructor")

    user = User.find_by!(username: "new-console")
    password = flash[:notice][/\b[a-z][A-Za-z0-9]{10}\d\b/]

    assert_not_nil password, "the flash should carry the generated password"
    assert_equal user, User.authenticate_by(username: user.username, password:)
  end

  test "the creation is audited as a privilege change" do
    assert_difference "AuditEvent.count", 1 do
      create_console_account(access: "instructor")
    end

    event = AuditEvent.order(:id).last
    assert_equal "console_account_created", event.action
    assert_equal :warn, event.level
    assert_match "new-console", event.text
  end

  # The password must not survive anywhere but the one flash.
  test "the audit row does not carry the password" do
    create_console_account(access: "instructor")
    password = flash[:notice][/\b[a-z][A-Za-z0-9]{10}\d\b/]

    assert_not_includes AuditEvent.order(:id).last.params.to_s, password
  end

  test "a non-admin cannot create a console account" do
    sign_out
    sign_in_as users(:instructor)

    assert_no_difference "User.count" do
      create_console_account(access: "admin")
    end

    assert_redirected_to root_path
  end
end
