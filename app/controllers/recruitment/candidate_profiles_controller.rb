module Recruitment
  class CandidateProfilesController < ApplicationController
    allow_only :student

    def edit
      @profile = Current.user.candidate_profile || Current.user.build_candidate_profile
      @resume_analysis = @profile.resume_analyses.newest_first.includes(:findings).first if @profile.persisted?
      build_fact_rows
    end

    def update
      @profile = Current.user.candidate_profile || Current.user.build_candidate_profile
      @profile.assign_attributes(profile_params)
      @profile.save!
      @profile.resume.purge if @profile.remove_resume == "1"
      @profile.portfolio_files.purge if @profile.remove_portfolio_files == "1"

      redirect_to edit_recruitment_candidate_profile_path,
                  notice: t("flash.recruitment_candidate_profile_saved")
    rescue ActiveRecord::RecordInvalid
      build_fact_rows
      render :edit, status: :unprocessable_entity
    end

    def export
      @profile = Current.user.candidate_profile
      payload = @profile ? @profile.export_payload : CandidateProfile.new(user: Current.user).export_payload
      send_data JSON.pretty_generate(payload), filename: "candidate-profile.json", type: "application/json",
                disposition: "attachment"
    end

    def destroy
      if (profile = Current.user.candidate_profile)
        profile.resume.purge
        profile.portfolio_files.purge
        profile.destroy!
      end

      redirect_to root_path, notice: t("flash.recruitment_candidate_profile_deleted")
    end

    private
      def profile_params
        permitted = params.expect(candidate_profile: [
          :headline, :summary, :preferred_location, :portfolio_url, :github_url, :linkedin_url,
          :salary_expectation_min, :salary_expectation_max, :salary_currency, :visibility,
          :application_data_reuse_consent, :resume, :remove_resume, :remove_portfolio_files,
          { portfolio_files: [], facts_attributes: [ [ :id, :kind, :title, :organization, :detail, :_destroy ] ] }
        ])
        permitted
      end

      def build_fact_rows
        existing_kinds = @profile.facts.map(&:kind)
        (CandidateProfileFact::KINDS - existing_kinds).each { |kind| @profile.facts.build(kind:) }
      end
  end
end
