require "test_helper"
require_relative "recovery_test_helper"

class RecoveryRestoreDrillTest < ActiveSupport::TestCase
  include RecoveryTestHelpers

  test "an isolated drill verifies integrity and stays inside the four-hour RTO" do
    started_at = 30.minutes.ago
    report = Recovery::Drill.verify!(
      manifest: valid_manifest(captured_at: 30.minutes.ago.iso8601),
      target: isolated_target,
      database: valid_database,
      storage: valid_storage,
      started_at:,
      finished_at: started_at + 2.hours
    )

    assert_equal "verified", report.fetch(:status)
    assert_equal 2.hours.to_i, report.fetch(:duration_seconds)
    assert_equal Recovery::Contract::RPO.to_i, report.fetch(:rpo_seconds)
    assert report.fetch(:checks).values.all?
  end

  test "a drill that exceeds the RTO emits a restore failure and is not verified" do
    started_at = Time.current

    payload = capture_signal("recovery.restore.failure") do
      assert_raises(Recovery::Drill::RtoExceeded) do
        Recovery::Drill.verify!(
          manifest: valid_manifest,
          target: isolated_target,
          database: valid_database,
          storage: valid_storage,
          started_at:,
          finished_at: started_at + Recovery::Contract::RTO + 1.second
        )
      end
    end

    assert_equal "rto_exceeded", payload.fetch(:fields).fetch("reason")
    assert_operator payload.fetch(:fields).fetch("duration_seconds"), :>, Recovery::Contract::RTO.to_i
  end
end
