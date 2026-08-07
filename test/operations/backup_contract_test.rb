require "test_helper"
require_relative "recovery_test_helper"

class RecoveryBackupContractTest < ActiveSupport::TestCase
  include RecoveryTestHelpers

  test "the contract inventories database, storage, and configuration without secret values" do
    assert_equal %w[postgresql active_storage configuration], Recovery::Contract::DATA_CLASSES.map { |it| it[:id] }
    assert_equal 1.hour, Recovery::Contract::RPO
    assert_equal 4.hours, Recovery::Contract::RTO
    assert_equal 1.hour, Recovery::Contract::BACKUP_INTERVAL
    assert_equal 3.months, Recovery::Contract::DRILL_INTERVAL
    assert(
      Recovery::Contract::DATA_CLASSES.none? do |data_class|
        data_class.values.any? { |value| value.to_s.match?(/password=|secret=|private_key=|BEGIN [A-Z ]+ KEY/i) }
      end
    )
  end

  test "a complete encrypted database and storage manifest is valid and fresh" do
    manifest = Recovery::Manifest.new(valid_manifest(captured_at: 59.minutes.ago.iso8601))

    assert_same manifest, manifest.validate!
    assert_same manifest, manifest.validate_fresh!(at: Time.current)
  end

  test "a stale manifest fails the one-hour RPO and emits a recovery signal" do
    captured_at = Recovery::Contract::RPO.ago - 1.second

    payload = capture_signal("recovery.backup.stale") do
      assert_raises(Recovery::Manifest::Stale) do
        Recovery::Manifest.new(valid_manifest(captured_at: captured_at.iso8601)).validate_fresh!
      end
    end

    assert_equal "synthetic-backup-001", payload.fetch(:fields).fetch("backup_id")
    assert_operator payload.fetch(:fields).fetch("age_seconds"), :>, Recovery::Contract::RPO.to_i
  end

  test "a manifest containing credentials is rejected without logging the value" do
    payload = capture_signal("recovery.backup.failure") do
      assert_raises(Recovery::Manifest::Invalid) do
        Recovery::Manifest.new(valid_manifest.merge(password: "never-log-this")).validate!
      end
    end

    assert_not_includes JSON.generate(payload), "never-log-this"
  end

  test "a malformed manifest is rejected as a recovery contract failure" do
    assert_raises(Recovery::Manifest::Invalid) { Recovery::Manifest.new(nil).validate! }
  end
end
