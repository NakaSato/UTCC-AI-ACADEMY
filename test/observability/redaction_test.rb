require "test_helper"

class ObservabilityRedactionTest < ActiveSupport::TestCase
  test "redacts prohibited keys recursively" do
    result = Observability::Redactor.call(
      password: "secret",
      cookie: "signed-cookie",
      request_body: { answer: "learner work" },
      student_id: "2011071730001",
      nested: { email: "learner@example.com", ip_address: "192.0.2.10" },
      safe: "course-progress"
    )

    assert_equal "[REDACTED]", result.fetch("password")
    assert_equal "[REDACTED]", result.fetch("cookie")
    assert_equal "[REDACTED]", result.fetch("request_body")
    assert_equal "[REDACTED]", result.fetch("student_id")
    assert_equal "[REDACTED]", result.fetch("nested").fetch("email")
    assert_equal "[REDACTED]", result.fetch("nested").fetch("ip_address")
    assert_equal "course-progress", result.fetch("safe")
  end

  test "redacts reset links even when nested under a non-sensitive key" do
    result = Observability::Redactor.call(
      details: "delivery failed for https://academy.example/reset-password/signed-token"
    )

    assert_equal "[REDACTED]", result.fetch("details")
  end

  test "telemetry does not serialize prohibited values" do
    payload = capture_signal("security.audit.failure") do
      Observability::Telemetry.emit(
        "security.audit.failure",
        action: "role_changed",
        student_id: "2011071730001",
        reset_link: "https://academy.example/reset-password/signed-token"
      )
    end

    serialized = JSON.generate(payload)
    assert_not_includes serialized, "2011071730001"
    assert_not_includes serialized, "signed-token"
    assert_includes serialized, "[REDACTED]"
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
