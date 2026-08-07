require "test_helper"

class ObservabilitySecurityEventBoundaryTest < ActiveSupport::TestCase
  test "security telemetry has no learner identity or durable-event payload by default" do
    payload = capture_signal("security.audit.failure") do
      Observability::Telemetry.emit(
        "security.audit.failure",
        action: "integrity_escalated",
        error_class: "ActiveRecord::RecordInvalid",
        user_id: users(:student).id,
        name: users(:student).name
      )
    end

    fields = payload.fetch(:fields)
    assert_equal "[REDACTED]", fields.fetch("user_id")
    assert_equal "[REDACTED]", fields.fetch("name")
    assert_not payload.key?(:user_id)
    assert_not payload.key?(:params)
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
