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
  # The second is that every number is a queue the viewer can open. Not one they
  # can empty: ADR-0048 decision 4 says an active member sees the whole board,
  # because a mentor who cannot decide a request is still better off knowing a
  # student has been waiting since Tuesday. Whether they may act is settled by
  # the controller that owns the action, which refuses today and keeps refusing.
  class CompanyDashboard
    Queue = Data.define(:key, :count, :path) do
      def any? = count.positive?
    end

    Posting = Data.define(:key, :published, :in_review)

    Collaboration = Data.define(:published_cases, :open_milestones, :submissions, :path) do
      def any? = published_cases.positive?
    end

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
        collaboration: collaboration,
        applications: OrganizationReporting.call(organization: @organization, viewer: @viewer)
      }
    end

    private
      # Ordered by how overdue each one tends to be, not alphabetically: a
      # student waiting on a decision has been waiting longest.
      def queues
        [
          Queue.new(:internship_requests, @organization.internship_requests.awaiting_company.count,
                    company_internship_requests_path),
          Queue.new(:progress_reports, unacknowledged_reports, internship_placements_path),
          Queue.new(:active_placements, @organization.internship_placements.open_placements.count,
                    internship_placements_path)
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

      # Deliberately not a queue. A submission has no reviewed state and no
      # acknowledgement — SPEC-0040 never gave it one — so a count of them is
      # what is running, not what is waiting, and the screen says so.
      def collaboration
        cases = @organization.business_cases.where(status: "published")
        case_ids = cases.select(:id)

        Collaboration.new(
          cases.count,
          BusinessCaseMilestone.where(business_case_id: case_ids, status: "open").count,
          BusinessCaseSubmission.where(business_case_id: case_ids).count,
          Rails.application.routes.url_helpers.business_cases_path
        )
      end

      def count_by_status(relation, status) = relation.where(status:).count

      def unacknowledged_reports
        InternshipProgressReport.where(acknowledged_at: nil)
                                .where(internship_placement_id: @organization.internship_placements.select(:id))
                                .count
      end

      def company_internship_requests_path
        Rails.application.routes.url_helpers.company_internship_requests_path(@organization)
      end

      def internship_placements_path
        Rails.application.routes.url_helpers.internship_placements_path
      end
  end
end
