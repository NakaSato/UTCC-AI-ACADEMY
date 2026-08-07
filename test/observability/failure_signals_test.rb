require "test_helper"

class ObservabilityFailureSignalsTest < ActiveSupport::TestCase
  class ControlledFailureJob < ApplicationJob
    def perform
      raise "controlled job failure"
    end
  end

  test "an HTTP 5xx notification emits a redacted failure signal" do
    payload = capture_signal("http.request.failure") do
      ActiveSupport::Notifications.instrument(
        "process_action.action_controller",
        controller: "LessonsController",
        action: "submit",
        status: 500,
        exception: [ "RuntimeError", "learner answer must not be copied" ]
      )
    end

    assert_equal 500, payload.fetch(:fields).fetch("status")
    assert_equal "RuntimeError", payload.fetch(:fields).fetch("error_class")
    assert_not_includes JSON.generate(payload), "learner answer"
  end

  test "a database failure notification emits a failure signal" do
    payload = capture_signal("database.query.failure") do
      ActiveSupport::Notifications.instrument(
        "sql.active_record",
        name: "User Load",
        exception: [ "ActiveRecord::StatementInvalid", "student_id=2011071730001" ]
      )
    end

    assert_equal "User Load", payload.fetch(:fields).fetch("operation")
    assert_equal "ActiveRecord::StatementInvalid", payload.fetch(:fields).fetch("error_class")
    assert_not_includes JSON.generate(payload), "2011071730001"
  end

  test "a mail delivery failure notification omits message contents" do
    payload = capture_signal("mail.delivery.failure") do
      ActiveSupport::Notifications.instrument(
        "deliver.action_mailer",
        mailer: "PasswordsMailer",
        action: "reset",
        exception: [ "Net::SMTPFatalError", "reset-password/signed-token" ]
      )
    end

    assert_equal "PasswordsMailer", payload.fetch(:fields).fetch("mailer")
    assert_equal "reset", payload.fetch(:fields).fetch("action")
    assert_not_includes JSON.generate(payload), "signed-token"
  end

  test "a failing job emits a signal and still raises to the queue adapter" do
    payload = capture_signal("job.failure") do
      assert_raises(RuntimeError) { ControlledFailureJob.perform_now }
    end

    assert_equal "ObservabilityFailureSignalsTest::ControlledFailureJob", payload.fetch(:fields).fetch("job_class")
    assert_equal "RuntimeError", payload.fetch(:fields).fetch("error_class")
    assert payload.fetch(:job_id).present?
  end

  test "an audit persistence failure emits a security signal and preserves the error" do
    Current.session = users(:one).sessions.create!

    payload = capture_signal("security.audit.failure") do
      assert_raises(ActiveRecord::RecordInvalid) { AuditEvent.record("not-an-approved-action") }
    end

    assert_equal "not-an-approved-action", payload.fetch(:fields).fetch("action")
    assert_equal "ActiveRecord::RecordInvalid", payload.fetch(:fields).fetch("error_class")
  end

  private
    def capture_signal(event)
      received = []
      subscription = ActiveSupport::Notifications.subscribe("observability.#{event}") do |*, payload|
        received << payload
      end
      yield
      received.sole
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end
end
