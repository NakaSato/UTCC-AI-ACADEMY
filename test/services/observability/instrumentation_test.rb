require "test_helper"

# Three global subscribers, installed once from an initializer, that turn a
# framework notification into an observability signal. They shipped with no test
# at all, which for a subscriber is a particular risk: it fails by going quiet,
# and a silent failure detector reads exactly like a healthy system.
class Observability::InstrumentationTest < ActiveSupport::TestCase
  # The initializer has already installed them by the time a test runs. Calling
  # install again must not subscribe a second set, or every incident would be
  # reported twice.
  setup { Observability::Instrumentation.install }

  def signals_from(event, payload)
    captured = []
    subscription = ActiveSupport::Notifications.subscribe(/\Aobservability\./) do |name, *, signal|
      captured << [ name, signal ]
    end
    ActiveSupport::Notifications.instrument(event, payload) { nil }
    captured
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  test "a failed request is reported once, with no request body" do
    signals = signals_from("process_action.action_controller",
                           controller: "SessionsController", action: "create", status: 500,
                           exception: [ "RuntimeError", "boom" ], params: { "password" => "hunter2" })

    assert_equal 1, signals.length, "installed twice — every incident would be reported twice"
    name, signal = signals.first
    assert_equal "observability.http.request.failure", name
    assert_equal "SessionsController", signal[:fields]["controller"]
    assert_equal "RuntimeError", signal[:fields]["error_class"]
    refute_includes signal.to_s, "hunter2"
  end

  test "a server error without an exception is still a failure" do
    signals = signals_from("process_action.action_controller",
                           controller: "HomeController", action: "show", status: 503)

    assert_equal 1, signals.length
  end

  test "a request that succeeded is not an incident" do
    assert_empty signals_from("process_action.action_controller",
                              controller: "HomeController", action: "show", status: 200)
  end

  test "an ordinary query is not an incident, and a failed one is" do
    assert_empty signals_from("sql.active_record", name: "User Load", sql: "SELECT 1")

    signals = signals_from("sql.active_record",
                           name: "User Load", sql: "SELECT 1", exception: [ "ActiveRecord::StatementInvalid", "no" ])

    assert_equal 1, signals.length
    assert_equal "observability.database.query.failure", signals.first.first
  end

  test "a mail delivery failure is reported when the payload carries one" do
    signals = signals_from("deliver.action_mailer",
                           mailer: "PasswordsMailer", action: "reset",
                           exception: [ "Net::SMTPServerBusy", "greylisted" ])

    assert_equal 1, signals.length
    assert_equal "observability.mail.delivery.failure", signals.first.first
  end
end
