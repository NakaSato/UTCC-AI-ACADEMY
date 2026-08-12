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
      counts = applications.group(:status).count
      total = counts.values.sum
      thin = total < MIN_REPORTING_CELL_SIZE

      # ADR-0037 suppresses totals *and* status cells below five. Deciding that
      # on the total alone published cells of one: six applications, five
      # submitted and one screening, cleared the gate and named the one person
      # who had reached screening to a reporter who can see who applied.
      cells = Recruitment::JobApplication::STATUSES.map do |status|
        count = counts.fetch(status, 0)
        suppressed = thin || small?(count)
        ApplicationStatusCell.new(status, suppressed ? nil : count, suppressed)
      end

      # The total goes with them. A single suppressed cell beside a published
      # total is not suppressed at all — it is the total minus the cells that
      # were published, which is arithmetic anybody can do on one screen. With
      # the total withheld a suppressed cell is known only to be between one and
      # four, which is what a threshold is allowed to leak.
      hidden = thin || cells.any?(&:suppressed)

      job_counts = Recruitment::JobPost.where(organization_id:).group(:status).count

      Summary.new(
        Recruitment::JobPost::STATUSES.map { |status| JobStatus.new(status, job_counts.fetch(status, 0)) },
        hidden ? nil : total,
        hidden,
        cells,
        I18n.t("recruitment.reporting.source_label"),
        I18n.t("recruitment.reporting.uncertainty", minimum: MIN_REPORTING_CELL_SIZE)
      )
    end

    private
      # A cell of zero names nobody. Suppressing it would redact most of a
      # normal report — six of seven statuses are usually empty — and protect
      # no one, so zero is published and only a real small population hides.
      def small?(count) = count.positive? && count < MIN_REPORTING_CELL_SIZE

      def reporter?
        organization_id = @organization&.id
        return false unless organization_id.present? && Organization.active.where(id: organization_id).exists?
        return true if User.where(id: @viewer&.id, role: "admin").exists?

        OrganizationMembership.where(organization_id:, user_id: @viewer&.id,
                                     status: "active", role: REPORTER_ROLES).exists?
      end
  end
end
