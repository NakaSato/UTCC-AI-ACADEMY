require "test_helper"

class ObservabilityRecoverySignalTest < ActiveSupport::TestCase
  RECOVERY_EVENTS = %w[
    recovery.backup.failure
    recovery.backup.stale
    recovery.restore.failure
    recovery.integrity.failure
  ].freeze

  test "recovery failure signals are part of the approved M9 observability contract" do
    signals = Observability::SignalCatalog.all.index_by { |signal| signal[:event] }

    RECOVERY_EVENTS.each do |event|
      signal = signals.fetch(event)

      assert_equal "critical", signal[:severity]
      assert signal[:owner].present?
      assert signal[:runbook].start_with?("docs/runbooks/rb-backup-restore-verification.md#")
      assert Rails.root.join(signal[:runbook].split("#", 2).first).file?
    end
  end

  test "recovery signals contain no provider credentials or restored learner data fields" do
    RECOVERY_EVENTS.each do |event|
      signal = Observability::SignalCatalog.fetch(event)
      contract = signal.values.join(" ").downcase

      assert_not_includes contract, "password"
      assert_not_includes contract, "password="
      assert_not_includes contract, "learner data"
    end
  end
end
