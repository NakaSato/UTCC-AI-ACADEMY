module Recruitment
  class JobDiscoveryPreferencesController < ApplicationController
    allow_only :student

    def edit
      @preference = Current.user.job_discovery_preference || Current.user.build_job_discovery_preference
    end

    def update
      @preference = Current.user.job_discovery_preference || Current.user.build_job_discovery_preference
      @preference.assign_attributes(preference_params)
      @preference.save!
      AuditEvent.record("recruitment_job_discovery_preferences_updated", alerts_enabled: @preference.alerts_enabled?,
                        frequency: @preference.alert_frequency)
      redirect_to edit_recruitment_job_discovery_preferences_path, notice: t("flash.recruitment_job_preferences_saved")
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    private
      def preference_params
        params.expect(recruitment_job_discovery_preference: [
          :alerts_enabled, :alert_consent, :alert_frequency, :search_query, :location, :employment_type, :remote_policy
        ])
      end
  end
end
