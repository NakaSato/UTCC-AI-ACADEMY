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

      applications = Recruitment::JobApplication.joins(:job_post)
                                                 .where(recruitment_job_posts: { organization_id: @organization.id })
      total = applications.count
      suppressed = total < MIN_REPORTING_CELL_SIZE
      Summary.new(
        Recruitment::JobPost::STATUSES.map { |status| JobStatus.new(status, @organization.job_posts.where(status:).count) },
        suppressed ? nil : total,
        suppressed,
        Recruitment::JobApplication::STATUSES.map do |status|
          ApplicationStatusCell.new(status, suppressed ? nil : applications.where(status:).count, suppressed)
        end,
        SOURCE_LABEL,
        UNCERTAINTY
      )
    end

    private
      def reporter?
        return false unless @organization&.active?
        return true if @viewer&.admin?

        @organization.memberships.active.exists?(user_id: @viewer&.id, role: REPORTER_ROLES)
      end
  end
end
