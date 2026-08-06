module Recovery
  module Contract
    RPO = 1.hour
    RTO = 4.hours
    BACKUP_INTERVAL = 1.hour
    DRILL_INTERVAL = 3.months

    DATA_CLASSES = [
      {
        id: "postgresql",
        source: "Managed PostgreSQL",
        includes: "Application rows, Active Record schema, Solid Queue, Solid Cable, and Solid Cache tables",
        recovery_target: "Provider-supported point-in-time restore or snapshot into an isolated database"
      },
      {
        id: "active_storage",
        source: "Active Storage local volume or approved object-storage target",
        includes: "Active Storage blobs and attached files referenced by database rows",
        recovery_target: "Isolated storage target captured at a compatible backup point"
      },
      {
        id: "configuration",
        source: "Release metadata and human-owned secret custody",
        includes: "Commit/artifact identity and configuration names; never secret values or key material",
        recovery_target: "Approved recovery owner retrieves secrets from the separate credential boundary"
      }
    ].freeze

    module_function

    def data_class(id)
      DATA_CLASSES.find { |data_class| data_class[:id] == id.to_s } ||
        raise(KeyError, "Unknown recovery data class: #{id}")
    end
  end
end
