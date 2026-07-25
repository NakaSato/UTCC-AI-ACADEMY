require "test_helper"
require "rake"

# `admin:create` is the only way to grant the first admin — /admin cannot, since
# opening it already requires the role. That makes it worth covering: it is a
# privilege-granting entry point that no controller test reaches.
class AdminTaskTest < ActiveSupport::TestCase
  ENV_KEYS = %w[ ADMIN_STUDENT_ID ADMIN_NAME ADMIN_PASSWORD ].freeze

  setup do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
    @original_env = ENV_KEYS.index_with { ENV[it] }
  end

  teardown { @original_env.each { |key, value| ENV[key] = value } }

  test "creates an admin from the environment" do
    assert_difference "User.count", 1 do
      run_task(student_id: "2011071730600", name: "ผู้ดูแลใหม่", password: "secret-password1")
    end

    user = User.find_by(student_id: "2011071730600")
    assert_predicate(user, :admin?)
    assert_predicate(user, :staff?)
    assert(user.authenticate("secret-password1"), "the password given is the one set")
  end

  test "promotes an existing account instead of duplicating it" do
    assert_no_difference "User.count" do
      run_task(student_id: users(:student).student_id)
    end

    assert_predicate(users(:student).reload, :admin?)
  end

  test "a padded student ID still finds the existing account" do
    assert_no_difference "User.count" do
      run_task(student_id: "  #{users(:student).student_id}  ")
    end

    assert_predicate(users(:student).reload, :admin?)
  end

  test "an existing admin is left alone" do
    assert_no_difference "User.count" do
      output = run_task(student_id: users(:admin).student_id)
      assert_match(/already an admin/, output)
    end
  end

  test "a rejected account aborts with the validation messages" do
    assert_no_difference "User.count" do
      error = assert_raises(SystemExit) do
        run_task(student_id: "not-13-digits", name: "x", password: "secret-password1")
      end

      assert_match(
        I18n.t("activerecord.errors.models.user.attributes.student_id.invalid"), error.message
      )
    end
  end

  test "a missing value aborts rather than prompting with no terminal" do
    assert_raises(SystemExit) { run_task(student_id: nil) }
  end

  private
    # The task prints its result, so the output is captured rather than dumped
    # into the suite's. Tests run without a terminal, which is exactly the
    # non-interactive path the task takes over `kamal app exec`.
    def run_task(student_id:, name: nil, password: nil)
      ENV["ADMIN_STUDENT_ID"] = student_id
      ENV["ADMIN_NAME"] = name
      ENV["ADMIN_PASSWORD"] = password

      capture_io { Rake::Task["admin:create"].execute }.first
    end
end
