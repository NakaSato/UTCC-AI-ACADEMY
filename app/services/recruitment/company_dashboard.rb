module Recruitment
  # What a company member should see first: the work waiting on them, and the
  # shape of what they have open. It is their front door, so it answers "what do
  # I do now" before it answers "how are we doing".
  #
  # Two rules decide what is allowed on it.
  #
  # The first is ADR-0037: aggregate statistics about *candidates* are governed,
  # restricted to reporter roles, and suppressed below five. This does not
  # reimplement any of that — where the dashboard wants an application figure it
  # asks `OrganizationReporting`, so the suppression rule is inherited rather
  # than copied, and a change there changes here.
  #
  # The second is that every number is a queue the viewer can already open. A
  # count of rows they cannot read would be a statistic about other people
  # dressed up as a task list.
  class CompanyDashboard
    Queue = Data.define(:key, :count, :path) do
      def any? = count.positive?
    end

    Posting = Data.define(:key, :published, :in_review)

    def self.call(organization:, viewer:) = new(organization:, viewer:).call

    def initialize(organization:, viewer:)
      @organization = organization
      @viewer = viewer
    end

    def call
      return unless @organization&.active?

      {
        queues: queues,
        postings: postings,
        applications: OrganizationReporting.call(organization: @organization, viewer: @viewer)
      }
    end

    private
      # Ordered by how overdue each one tends to be, not alphabetically: a
      # student waiting on a decision has been waiting longest.
      def queues
        [
          Queue.new(:internship_requests, decidable_requests, company_internship_requests_path),
          Queue.new(:progress_reports, unacknowledged_reports, internship_placements_path),
          Queue.new(:active_placements, open_placements, internship_placements_path)
        ]
      end

      def postings
        [
          Posting.new(:jobs, count_by_status(@organization.job_posts, "published"),
                      count_by_status(@organization.job_posts, "review")),
          Posting.new(:internships, count_by_status(@organization.internship_programs, "published"),
                      count_by_status(@organization.internship_programs, "review"))
        ]
      end

      def count_by_status(relation, status) = relation.where(status:).count

      # Only a decider sees the decision queue, because only a decider can empty
      # it — see InternshipRequest::DECIDER_ROLES.
      def decidable_requests
        return 0 unless member_in?(InternshipRequest::DECIDER_ROLES)

        @organization.internship_requests.awaiting_company.count
      end

      def unacknowledged_reports
        return 0 unless member_in?(InternshipPlacement::DECIDER_ROLES)

        InternshipProgressReport.where(acknowledged_at: nil)
                                .where(internship_placement_id: @organization.internship_placements.select(:id))
                                .count
      end

      def open_placements
        return 0 unless member_in?(InternshipPlacement::DECIDER_ROLES)

        @organization.internship_placements.open_placements.count
      end

      # An admin is not a member and holds no organization role, but may read
      # any organization — the same rule `Organization#visible_to?` applies.
      def member_in?(roles)
        return true if @viewer&.admin?

        @organization.memberships.active.exists?(user_id: @viewer&.id, role: roles)
      end

      def company_internship_requests_path
        Rails.application.routes.url_helpers.company_internship_requests_path(@organization)
      end

      def internship_placements_path
        Rails.application.routes.url_helpers.internship_placements_path
      end
  end
end
