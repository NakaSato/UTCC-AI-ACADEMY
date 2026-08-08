module Recruitment
  class OrganizationReporting
    JobStatus = Data.define(:status, :count)
    ApplicationStatusCell = Data.define(:status, :count, :suppressed)
    Summary = Data.define(:job_statuses, :application_total, :application_total_suppressed, :application_statuses,
                          :source_label, :uncertainty)

    REPORTER_ROLES = Recruitment::JobPost::AUTHOR_ROLES
    MIN_REPORTING_CELL_SIZE = 5
    SOURCE_LABEL = "Read-time aggregates from organization job-post and application workflow records."
    UNCERTAINTY = "These are descriptive workflow counts, not hiring quality, fairness, AI-effectiveness, or causal outcome measures. Application populations below five are suppressed."

    def self.call(organization:, viewer:)
      new(organization:, viewer:).call
    end

    def initialize(organization:, viewer:)
      @organization = organization
      @viewer = viewer
    end

    def call
      return unless reporter?

      organization_id = @organization.id
      applications = Recruitment::JobApplication.joins(:job_post)
                                                 .where(recruitment_job_posts: { organization_id: })
      total = applications.count
      suppressed = total < MIN_REPORTING_CELL_SIZE
      Summary.new(
        Recruitment::JobPost::STATUSES.map do |status|
          JobStatus.new(status, Recruitment::JobPost.where(organization_id:, status:).count)
        end,
        suppressed ? nil : total,
        suppressed,
        Recruitment::JobApplication::STATUSES.map do |status|
          ApplicationStatusCell.new(status, suppressed ? nil : applications.where(status:).count, suppressed)
        end,
        I18n.t("recruitment.reporting.source_label"),
        I18n.t("recruitment.reporting.uncertainty", minimum: MIN_REPORTING_CELL_SIZE)
      )
    end

    private
      def reporter?
        organization_id = @organization&.id
        return false unless organization_id.present? && Organization.active.where(id: organization_id).exists?
        return true if User.where(id: @viewer&.id, role: "admin").exists?

        OrganizationMembership.where(organization_id:, user_id: @viewer&.id,
                                     status: "active", role: REPORTER_ROLES).exists?
      end
  end
end
