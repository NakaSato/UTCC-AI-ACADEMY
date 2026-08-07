module Recovery
  class Manifest
    class Invalid < StandardError; end
    class Stale < Invalid; end

    REQUIRED_KEYS = %w[backup_id captured_at database storage encryption].freeze
    FORBIDDEN_KEYS = %r{\A(?:password|secret|credential|private_key|key_material|raw_data|learner_data)\z}i

    attr_reader :attributes

    def initialize(attributes)
      @attributes = stringify_keys(attributes)
      @attributes = {} unless @attributes.is_a?(Hash)
    end

    def validate!
      errors = []
      errors.concat(REQUIRED_KEYS.reject { |key| attributes.key?(key) })
      errors << "captured_at" unless captured_at
      errors << "database" unless complete_data_class?("database")
      errors << "storage" unless complete_data_class?("storage")
      errors << "encryption" unless encrypted?
      errors << "forbidden_fields" if forbidden_field?(attributes)

      return self if errors.empty?

      emit_failure("manifest_invalid", errors.size)
      raise Invalid, "backup manifest is invalid: #{errors.join(', ')}"
    end

    def validate_fresh!(at: Time.current)
      validate!
      return self if age_seconds(at) <= Contract::RPO.to_i

      Observability::Telemetry.emit(
        "recovery.backup.stale",
        backup_id: attributes["backup_id"],
        age_seconds: age_seconds(at).round
      )
      raise Stale, "backup manifest is older than the approved RPO"
    end

    def age_seconds(at = Time.current)
      at.to_time - captured_at.to_time
    end

    private
      def captured_at
        @captured_at ||= Time.iso8601(attributes["captured_at"].to_s)
      rescue ArgumentError
        nil
      end

      def complete_data_class?(key)
        value = attributes[key]
        value.is_a?(Hash) && value["included"] == true && value["integrity"] == "verified"
      end

      def encrypted?
        value = attributes["encryption"]
        value.is_a?(Hash) && value["at_rest"] == true && value["key_owner"].present?
      end

      def forbidden_field?(value)
        case value
        when Hash
          value.any? { |key, child| key.to_s.match?(FORBIDDEN_KEYS) || forbidden_field?(child) }
        when Array
          value.any? { |child| forbidden_field?(child) }
        else
          false
        end
      end

      def emit_failure(reason, error_count)
        Observability::Telemetry.emit(
          "recovery.backup.failure",
          backup_id: attributes["backup_id"],
          reason:,
          error_count:
        )
      end

      def stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, child), result| result[key.to_s] = stringify_keys(child) }
        when Array
          value.map { |child| stringify_keys(child) }
        else
          value
        end
      end
  end
end
