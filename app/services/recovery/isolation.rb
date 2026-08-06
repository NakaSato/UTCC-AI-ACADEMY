module Recovery
  module Isolation
    class UnsafeTarget < StandardError; end

    REQUIRED = %w[
      production_writes_disabled outbound_mail_disabled notifications_disabled
      websocket_target credentials_scope source_immutable
    ].freeze

    module_function

    def validate!(target)
      target = stringify_keys(target)
      target = {} unless target.is_a?(Hash)
      errors = REQUIRED.reject { |key| target.key?(key) }
      errors << "production_writes_disabled" unless target["production_writes_disabled"] == true
      errors << "outbound_mail_disabled" unless target["outbound_mail_disabled"] == true
      errors << "notifications_disabled" unless target["notifications_disabled"] == true
      errors << "websocket_target" unless target["websocket_target"] == "isolated"
      errors << "credentials_scope" unless target["credentials_scope"] == "non-production"
      errors << "source_immutable" unless target["source_immutable"] == true

      return target if errors.empty?

      Observability::Telemetry.emit("recovery.restore.failure", reason: "unsafe_target", error_count: errors.size)
      raise UnsafeTarget, "restore target is unsafe: #{errors.uniq.join(', ')}"
    end

    def stringify_keys(value)
      value.each_with_object({}) { |(key, child), result| result[key.to_s] = child } if value.is_a?(Hash)
    end
  end
end
