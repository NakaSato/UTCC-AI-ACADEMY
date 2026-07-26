require "test_helper"
require "rake"

# `instructor:create` grants staff access from the CLI, so it is covered for the
# same reason `admin:create` is: a privilege-granting entry point no controller
# test reaches. The case worth the most here is the last one — the task must not
# demote an admin, because that is the one path that could leave the app with no
# admin at all.
class InstructorTaskTest < ActiveSupport::TestCase
  ENV_KEYS = %w[ INSTRUCTOR_STUDENT_ID INSTRUCTOR_NAME INSTRUCTOR_PASSWORD ].freeze

  setup do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
    @original_env = ENV_KEYS.index_with { ENV[it] }
  end

  teardown { @original_env.each { |key, value| ENV[key] = value } }

  test "creates an instructor from the environment" do
    assert_difference "User.count", 1 do
      run_task(student_id: "2011071730700", name: "อาจารย์ใหม่", password: "secret-password1")
    end

    user = User.find_by(student_id: "2011071730700")
    assert_predicate(user, :instructor?)
    assert_predicate(user, :staff?)
    assert_not_predicate(user, :admin?)
    assert(user.authenticate("secret-password1"), "the password given is the one set")
  end

  test "promotes an existing student instead of duplicating it" do
    assert_no_difference "User.count" do
      run_task(student_id: users(:student).student_id)
    end

    assert_predicate(users(:student).reload, :instructor?)
  end

  test "a padded student ID still finds the existing account" do
    assert_no_difference "User.count" do
      run_task(student_id: "  #{users(:student).student_id}  ")
    end

    assert_predicate(users(:student).reload, :instructor?)
  end

  test "an existing instructor is left alone" do
    assert_no_difference "User.count" do
      output = run_task(student_id: users(:instructor).student_id)
      assert_match(/already an instructor/, output)
    end
  end

  # admin is a superset of instructor, so there is nothing to grant — and writing
  # the role would demote the account.
  test "an admin is left alone rather than demoted" do
    output = run_task(student_id: users(:admin).student_id)

    assert_predicate(users(:admin).reload, :admin?)
    assert_match(/already an admin/, output)
    assert_match(/unchanged/, output)
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
      ENV["INSTRUCTOR_STUDENT_ID"] = student_id
      ENV["INSTRUCTOR_NAME"] = name
      ENV["INSTRUCTOR_PASSWORD"] = password

      capture_io { Rake::Task["instructor:create"].execute }.first
    end
end
