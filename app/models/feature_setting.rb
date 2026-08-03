class FeatureSetting < ApplicationRecord
  GLOBAL_SCOPE = "global".freeze

  DEFINITIONS = {
    "notifications" => { default: true, actor_roles: %w[ admin ] },
    "search" => { default: true, actor_roles: %w[ admin ] },
    "leaderboard" => { default: false, actor_roles: %w[ admin ] }
  }.freeze

  KEYS = DEFINITIONS.keys.freeze

  validates :key, inclusion: { in: KEYS }
  validates :scope, inclusion: { in: [ GLOBAL_SCOPE ] }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :key, uniqueness: { scope: :scope }

  class << self
    def definition(key)
      DEFINITIONS[key.to_s]
    end

    def enabled?(key)
      definition = self.definition(key)
      return false unless definition

      record = find_by(key: key.to_s, scope: GLOBAL_SCOPE)
      record ? record.enabled : definition[:default]
    end

    def admin_rows
      KEYS.map do |key|
        find_by(key:, scope: GLOBAL_SCOPE) || new(key:, scope: GLOBAL_SCOPE, enabled: definition(key)[:default])
      end
    end

    def parse_boolean(value)
      case value
      when true, "true", "1" then true
      when false, "false", "0" then false
      end
    end

    def update!(key:, enabled:, expected_lock_version:)
      raise ActiveRecord::RecordInvalid, new(key:) unless definition(key)

      record = find_or_initialize_by(key: key.to_s, scope: GLOBAL_SCOPE)
      record.enabled = enabled
      record.lock_version = expected_lock_version.to_i unless record.new_record?
      record.save!
      record
    end
  end
end
