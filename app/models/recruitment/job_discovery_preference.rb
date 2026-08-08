module Recruitment
  class JobDiscoveryPreference < ApplicationRecord
    self.table_name = "recruitment_job_discovery_preferences"

    FREQUENCIES = %w[ daily weekly ].freeze

    belongs_to :user, inverse_of: :job_discovery_preference

    normalizes :alert_frequency, :search_query, :location, :employment_type, :remote_policy,
               with: ->(value) { value.to_s.strip.downcase }

    validates :user_id, uniqueness: true
    validates :alert_frequency, inclusion: { in: FREQUENCIES }
    validates :search_query, :location, length: { maximum: 160 }
    validates :employment_type, inclusion: { in: Recruitment::JobPost::EMPLOYMENT_TYPES }, allow_blank: true
    validates :remote_policy, inclusion: { in: Recruitment::JobPost::REMOTE_POLICIES }, allow_blank: true
    validate :student_owner
    validate :consent_for_alerts

    before_validation :stamp_consent

    def alerts_due?
      return false unless alerts_enabled? && alert_consent?
      return true if last_alert_sent_at.blank?

      last_alert_sent_at <= Time.current - (alert_frequency == "daily" ? 1.day : 7.days)
    end

    private
      def student_owner
        errors.add(:user, :invalid) unless user&.student?
      end

      def consent_for_alerts
        errors.add(:alert_consent, :invalid) if alerts_enabled? && !alert_consent?
      end

      def stamp_consent
        return unless will_save_change_to_alert_consent?

        self.alert_consent_given_at = alert_consent? ? Time.current : nil
        self.alerts_enabled = false unless alert_consent?
      end
  end
end
