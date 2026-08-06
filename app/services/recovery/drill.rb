module Recovery
  class Drill
    class RtoExceeded < StandardError; end

    def self.verify!(manifest:, target:, database:, storage:, started_at:, finished_at:)
      Manifest.new(manifest).validate_fresh!(at: started_at)
      Isolation.validate!(target)
      checks = Integrity.verify!(database:, storage:)
      duration_seconds = finished_at.to_time - started_at.to_time

      if duration_seconds > Contract::RTO.to_i
        Observability::Telemetry.emit(
          "recovery.restore.failure",
          reason: "rto_exceeded",
          duration_seconds: duration_seconds.round
        )
        raise RtoExceeded, "restore exceeded the approved RTO"
      end

      {
        status: "verified",
        duration_seconds: duration_seconds.round,
        rpo_seconds: Contract::RPO.to_i,
        rto_seconds: Contract::RTO.to_i,
        checks:
      }
    end
  end
end
