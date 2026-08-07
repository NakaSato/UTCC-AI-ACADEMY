module Recovery
  module Integrity
    class Invalid < StandardError; end

    module_function

    def verify!(database:, storage:)
      database = stringify_keys(database)
      storage = stringify_keys(storage)
      database = {} unless database.is_a?(Hash)
      storage = {} unless storage.is_a?(Hash)
      checks = {
        foreign_keys: database["foreign_keys_valid"] == true,
        schema_compatible: database["schema_compatible"] == true,
        row_counts: database["row_counts_verified"] == true,
        blob_references: storage["blob_references_valid"] == true,
        blob_checksums: storage["checksums_verified"] == true
      }

      return checks if checks.values.all?

      failed_checks = checks.filter_map { |name, passed| name.to_s unless passed }
      Observability::Telemetry.emit(
        "recovery.integrity.failure",
        failed_checks: failed_checks.join(",")
      )
      raise Invalid, "recovery integrity checks failed: #{failed_checks.join(', ')}"
    end

    def stringify_keys(value)
      value.each_with_object({}) { |(key, child), result| result[key.to_s] = child } if value.is_a?(Hash)
    end
  end
end
