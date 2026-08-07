module Recruitment
  class JobAlertNotifier
    def self.call(user:, recommendations:)
      new(user:, recommendations:).call
    end

    def initialize(user:, recommendations:)
      @user = user
      @recommendations = recommendations
    end

    def call
      return unless @user&.student? && @recommendations.present?

      preference = @user.job_discovery_preference
      return unless preference

      preference.with_lock do
        return unless preference.alerts_due?

        notification = Notification.notify(@user, "recruitment_job_alert", count: @recommendations.size)
        preference.update!(last_alert_sent_at: Time.current) if notification
      end
    end
  end
end
