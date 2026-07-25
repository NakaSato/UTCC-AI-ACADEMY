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

  test "student_id is required" do
    user = User.new(name: "ว่าง", student_id: "", password: "secret-password1")

    assert_not(user.valid?)
    assert_predicate(user.errors[:student_id], :any?)
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
