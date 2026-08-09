require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "downcases and strips student_id" do
    user = User.new(student_id: " 2011071730001 ")
    assert_equal("2011071730001", user.student_id)
  end

  # Required at sign-up and nowhere else: an admin-created console account has no
  # student card. RegistrationsController is what saves in this context.
  test "student_id is required to sign up" do
    user = User.new(name: "ว่าง", student_id: "", password: "secret-password1")

    assert_not(user.valid?(:registration))
    assert_predicate(user.errors[:student_id], :any?)
  end

  test "an account with no identifier at all is invalid" do
    user = User.new(name: "ไร้ชื่อเรียก", password: "secret-password1")

    assert_not(user.valid?)
    assert_predicate(user.errors[:base], :any?)
  end

  test "a username or an email address is identifier enough" do
    [ { username: "console-one" }, { email_address: "console@example.com" } ].each do |identity|
      user = User.new(name: "คอนโซล", password: "secret-password1", **identity)

      assert_predicate(user, :valid?, "#{identity.inspect} should be enough to identify an account")
    end
  end

  test "downcases and strips username, and blanks it to nil" do
    assert_equal("wichai", User.new(username: " WICHAI ").username)
    assert_nil(User.new(username: "  ").username)
  end

  test "username must be unique" do
    duplicate = User.new(name: "ซ้ำ", username: users(:console_instructor).username,
                         password: "secret-password1")

    assert_not(duplicate.valid?)
    assert_predicate(duplicate.errors[:username], :any?)
  end

  # The all-digit rule is load-bearing rather than cosmetic: console sign-in
  # reads an all-digit entry as a student ID, so an all-digit username would be
  # a name nobody could sign in with.
  test "username must be 3-30 characters, lowercase, and contain a letter" do
    # "Wichai" is absent on purpose: the normalizer downcases before any of this
    # runs, so a capital is corrected rather than refused.
    [ "ab", "a" * 31, "12345", "wichai wong", "wichai!", "-wichai", "wichai-" ].each do |bad|
      user = User.new(name: "x", username: bad, password: "secret-password1")

      assert_not(user.valid?, "#{bad.inspect} should be rejected")
      assert_predicate(user.errors[:username], :any?)
    end

    [ "abc", "wichai", "utcc-admin", "north.star_1" ].each do |good|
      user = User.new(name: "x", username: good, password: "secret-password1")

      assert_predicate(user, :valid?, "#{good.inspect} should be accepted")
    end
  end

  # Membership before role, and that ordering is the point: a company member
  # holds the student role, so asking `student?` first hands a recruiter a
  # learner's navigation and a heart counter.
  test "workspace answers membership before role" do
    organization = Organization.create!(name: "Workspace Co", creator: users(:admin))
    member = users(:console_company)
    organization.memberships.create!(user: member, role: "recruiter")

    assert_equal :student, users(:student).workspace
    assert_equal :instructor, users(:instructor).workspace
    assert_equal :admin, users(:admin).workspace
    assert_equal :company, member.workspace
    assert_predicate member, :student?
  end

  test "an instructor who is also a company member stays in the teaching app" do
    organization = Organization.create!(name: "Both Co", creator: users(:admin))
    instructor = users(:console_instructor)
    organization.memberships.create!(user: instructor, role: "mentor")

    assert_equal :instructor, instructor.workspace
  end

  # What every screen prints where it used to print the student ID.
  test "identifier falls back from student ID to username to email" do
    assert_equal(users(:student).student_id, users(:student).identifier)
    assert_equal("console-teacher", users(:console_instructor).identifier)
    assert_equal("no-name@example.com", User.new(email_address: "no-name@example.com").identifier)
  end

  # An admin relays it once; the policy has to accept it every time.
  test "a generated temporary password satisfies the password policy" do
    20.times do
      user = User.new(name: "x", username: "console-generated", password: User.generate_temporary_password)

      assert_predicate(user, :valid?, "#{user.password.inspect} should satisfy the policy")
    end
  end

  test "student_id must be unique" do
    duplicate = User.new(name: "ซ้ำ", student_id: users(:student).student_id,
                         password: "secret-password1")

    assert_not(duplicate.valid?)
    assert_predicate(duplicate.errors[:student_id], :any?)
  end

  test "student_id must be exactly 13 digits" do
    [
      "201107173090",     # 12 digits
      "20110717309012",   # 14 digits
      "201107173090a",    # a letter in the last position
      "2011 071730901",   # a space
      "a@b",
      "12-34"
    ].each do |bad|
      user = User.new(name: "x", student_id: bad, password: "secret-password1")
      assert_not(user.valid?, "#{bad.inspect} should be rejected")
      assert_predicate(user.errors[:student_id], :any?)
    end

    good = User.new(name: "x", student_id: "2011071730910", password: "secret-password1")
    assert(good.valid?, good.errors.full_messages.to_sentence)
  end

  test "the invalid student_id message states the rule" do
    user = User.new(name: "x", student_id: "123", password: "secret-password1")
    user.valid?

    assert_equal([ "ต้องเป็นตัวเลข 13 หลัก" ], user.errors[:student_id])
    I18n.with_locale(:en) do
      other = User.new(name: "x", student_id: "123", password: "secret-password1")
      other.valid?
      assert_equal([ "must be exactly 13 digits" ], other.errors[:student_id])
    end
  end

  test "a good password is accepted" do
    [ "utcc2026", "secret-password1", "Test!123", "ก้าวหน้า2026", "a1" + "x" * 70 ].each do |good|
      user = User.new(name: "x", student_id: "2011071730920", password: good)
      user.valid?
      assert_empty(user.errors[:password], "#{good.inspect} should be accepted")
    end
  end

  test "a bad password is rejected, and the message says why" do
    {
      "Test!12"      => :too_short,             # 7 characters
      "a1" + "x" * 71 => :too_long,             # 73, past bcrypt's ceiling
      "onlyletters"  => :missing_digit,
      "12345678901"  => :missing_letter,
      "password123"  => :too_common,
      "x2011071730920y" => :contains_student_id
    }.each do |bad, reason|
      user = User.new(name: "x", student_id: "2011071730920", password: bad)

      assert_not(user.valid?, "#{bad.inspect} should be rejected")
      expected = case reason
      when :too_short then I18n.t("errors.messages.too_short", count: 8)
      when :too_long  then I18n.t("errors.messages.too_long", count: 72)
      else I18n.t("activerecord.errors.models.user.attributes.password.#{reason}")
      end
      assert_includes(user.errors[:password], expected, "#{bad.inspect} → #{reason}")
    end
  end

  test "every rule a password breaks is reported at once" do
    user = User.new(name: "x", student_id: "2011071730920", password: "!!!!!!!!")
    user.valid?

    assert_equal(2, user.errors[:password].size, user.errors[:password].inspect)
  end

  test "an account needs no email address" do
    user = User.new(name: "ไม่มีอีเมล", student_id: "2011071730903", password: "secret-password1")

    assert(user.valid?)
    assert_nil(user.email_address)
  end

  test "several accounts can have no email address" do
    User.create!(name: "ก", student_id: "2011071730904", password: "secret-password1")
    second = User.new(name: "ข", student_id: "2011071730905", password: "secret-password1")

    assert(second.valid?, "a blank email must not collide with another blank one")
  end

  test "a new account is a student" do
    user = User.create!(name: "ใหม่", student_id: "2011071730930", password: "secret-password1")

    assert_equal("student", user.role)
    assert_predicate(user, :student?)
    assert_not_predicate(user, :staff?)
  end

  test "staff? covers instructor and admin, and nobody else" do
    assert_predicate(users(:instructor), :staff?)
    assert_predicate(users(:admin), :staff?)
    assert_not_predicate(users(:student), :staff?)
  end

  test "an unknown role fails validation rather than raising" do
    user = users(:student)
    user.role = "wizard"

    assert_not(user.valid?)
    assert_predicate(user.errors[:role], :any?)
  end

  test "an email address, when given, is still unique and well formed" do
    duplicate = User.new(name: "ซ้ำ", student_id: "2011071730906",
                         email_address: users(:one).email_address, password: "secret-password1")
    assert_not(duplicate.valid?)
    assert_predicate(duplicate.errors[:email_address], :any?)

    malformed = User.new(name: "เสีย", student_id: "2011071730907",
                         email_address: "not-an-email", password: "secret-password1")
    assert_not(malformed.valid?)
  end
end
