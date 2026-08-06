require "test_helper"

class TelemetryContractTest < ActiveSupport::TestCase
  test "every critical signal has a complete provider-neutral contract" do
    Observability::SignalCatalog.all.each do |signal|
      missing = Observability::SignalCatalog::REQUIRED_KEYS - signal.keys

      assert_empty missing, "#{signal[:event]} is missing #{missing.join(', ')}"
      assert_includes %w[info high critical], signal[:severity]
      assert_path_exists signal[:runbook]
    end
  end

  test "signal event names and metrics are unique" do
    assert_equal Observability::SignalCatalog.all.size,
                 Observability::SignalCatalog.all.map { |signal| signal[:event] }.uniq.size
    assert_equal Observability::SignalCatalog.all.size,
                 Observability::SignalCatalog.all.map { |signal| signal[:metric] }.uniq.size
  end

  test "telemetry carries only safe correlation and release context" do
    Current.request_id = "request-test-123"
    Current.job_id = "job-test-456"

    payload = capture_signal("http.request.failure") do
      Observability::Telemetry.emit("http.request.failure", status: 503, user_id: 42)
    end

    assert_equal "request-test-123", payload.fetch(:request_id)
    assert_equal "job-test-456", payload.fetch(:job_id)
    assert_equal "[REDACTED]", payload.fetch(:fields).fetch("user_id")
    assert_equal "503", payload.fetch(:fields).fetch("status").to_s
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

    def assert_path_exists(path)
      file_path = path.to_s.split("#", 2).first
      assert Rails.root.join(file_path).file?, "expected #{path} to exist"
    end
end
