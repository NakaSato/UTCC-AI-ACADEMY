require "test_helper"
require_relative "recovery_test_helper"

class RecoveryIntegrityTest < ActiveSupport::TestCase
  include RecoveryTestHelpers

  test "database and storage integrity checks cover foreign keys, schema, counts, references, and checksums" do
    checks = Recovery::Integrity.verify!(database: valid_database, storage: valid_storage)

    assert_equal %i[foreign_keys schema_compatible row_counts blob_references blob_checksums], checks.keys
    assert checks.values.all?
  end

  test "a missing blob reference fails recovery and emits the failed check" do
    payload = capture_signal("recovery.integrity.failure") do
      assert_raises(Recovery::Integrity::Invalid) do
        Recovery::Integrity.verify!(
          database: valid_database,
          storage: valid_storage.merge(blob_references_valid: false)
        )
      end
    end

    assert_equal "blob_references", payload.fetch(:fields).fetch("failed_checks")
  end

  test "an incompatible schema cannot be declared recovered" do
    assert_raises(Recovery::Integrity::Invalid) do
      Recovery::Integrity.verify!(
        database: valid_database.merge(schema_compatible: false),
        storage: valid_storage
      )
    end
  end

  test "missing recovery data is an explicit integrity failure" do
    assert_raises(Recovery::Integrity::Invalid) do
      Recovery::Integrity.verify!(database: nil, storage: nil)
    end
  end
end
