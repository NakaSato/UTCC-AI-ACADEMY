class FeatureSetting < ApplicationRecord
  GLOBAL_SCOPE = "global".freeze

  DEFINITIONS = {
    "notifications" => { default: true, actor_roles: %w[ admin ] },
    "search" => { default: true, actor_roles: %w[ admin ] },
    "leaderboard" => { default: false, actor_roles: %w[ admin ] }
  }.freeze

  KEYS = DEFINITIONS.keys.freeze

  # Any write clears the read-once memo, not only the approved class method:
  # a console session, a test, or a future caller updating a row directly would
  # otherwise leave this request reading the value it just replaced. The model
  # knows when it changed; nothing else has to remember to say so.
  after_commit { self.class.forget }

  validates :key, inclusion: { in: KEYS }
  validates :scope, inclusion: { in: [ GLOBAL_SCOPE ] }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :key, uniqueness: { scope: :scope }

  class << self
    def definition(key)
      DEFINITIONS[key.to_s]
    end

    # Three rows, read once for the length of a request and folded in Ruby —
    # the same bargain as the syllabus and the landing copy, and held on Current
    # for the same reason: a module-level memo outlives the database it was read
    # from, which breaks the moment the parallel test runner forks.
    #
    # It is worth the object because of how often the question is asked, not how
    # expensive it is to answer. The feature-control tab ran forty-six identical
    # `find_by`s in one render: every flag row asks, the header and footer ask,
    # and `admin_rows` asked once per key inside a loop that ran once per flag.
    def settings
      Current.feature_settings ||= where(scope: GLOBAL_SCOPE).index_by(&:key)
    end

    def forget = Current.feature_settings = nil

    def enabled?(key)
      definition = self.definition(key)
      return false unless definition

      record = settings[key.to_s]
      record ? record.enabled : definition[:default]
    end

    def admin_rows
      KEYS.map do |key|
        settings[key] || new(key:, scope: GLOBAL_SCOPE, enabled: definition(key)[:default])
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
