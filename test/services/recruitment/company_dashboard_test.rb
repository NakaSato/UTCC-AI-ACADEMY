require "test_helper"

# The counts behind the company work surface. ADR-0048 decision 4: every active
# member sees the same board, because a mentor who cannot decide a request is
# still better off knowing a student has been waiting. Decision 5: candidate
# figures keep the gate SPEC-0037 put on them, because they come from
# OrganizationReporting rather than from a count written here.
class Recruitment::CompanyDashboardTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Work Org", creator: users(:admin),
                                         accepts_internship_requests: true)
    @owner = users(:one)
    @mentor = users(:instructor)
    @organization.memberships.create!(user: @owner, role: "owner")
    @organization.memberships.create!(user: @mentor, role: "mentor")
  end

  test "requests awaiting a decision are counted, and decided ones are not" do
    submitted_request_for(users(:student))
    decided = submitted_request_for(users(:two))
    decided.reject!(actor: @owner, reason: "Not this term")

    assert_equal 1, queue(@owner, :internship_requests).count
    assert_equal Rails.application.routes.url_helpers.company_internship_requests_path(@organization),
                 queue(@owner, :internship_requests).path
  end

  # Decision 4. The mentor is outside InternshipRequest::DECIDER_ROLES and
  # cannot decide any of these; they still see that somebody is waiting.
  test "a member outside the decider roles sees the same internship figures" do
    submitted_request_for(users(:student))

    %i[internship_requests progress_reports active_placements].each do |key|
      assert_equal queue(@owner, key).count, queue(@mentor, key).count,
                   "#{key} must not depend on the viewer's role"
    end
  end

  test "an acknowledged progress report leaves the queue" do
    placement = active_placement_for(users(:student))
    report = placement.progress_reports.create!(activities: "Mapped the routes")

    assert_equal 1, queue(@owner, :progress_reports).count

    report.acknowledge!(actor: @owner)
    assert_equal 0, queue(@owner, :progress_reports).count
  end

  test "planned and active placements are open, and a completed one is not" do
    active_placement_for(users(:student))
    finished = active_placement_for(users(:two))

    assert_equal 2, queue(@owner, :active_placements).count

    finished.complete!(actor: @owner)
    assert_equal 1, queue(@owner, :active_placements).count
  end

  # Decision 5: the suppression is inherited, not copied. Four applications is
  # below SPEC-0037's minimum cell size of five.
  test "application figures keep the reporting gate and the suppression" do
    job = published_job
    4.times { |index| application_for(job, index) }

    reporter = Recruitment::CompanyDashboard.call(organization: @organization, viewer: @owner)
    assert reporter[:applications].application_total_suppressed
    assert_nil reporter[:applications].application_total

    # A mentor is not a reporter role, so there are no application figures at
    # all — and the rest of the board is still there.
    mentor_board = Recruitment::CompanyDashboard.call(organization: @organization, viewer: @mentor)
    assert_nil mentor_board[:applications]
    assert_equal 3, mentor_board[:queues].length
  end

  test "postings count what is published and what is in review" do
    published_job
    @organization.job_posts.create!(creator: @owner, title: "Draft Job", summary: "Summary",
                                    description: "Description", category: "Product", department: "Academy",
                                    team: "Platform", seniority: "Junior", location: "Bangkok")
                 .transition_to!("review")

    jobs = Recruitment::CompanyDashboard.call(organization: @organization, viewer: @owner)[:postings]
                                        .find { |posting| posting.key == :jobs }

    assert_equal 1, jobs.published
    assert_equal 1, jobs.in_review
  end

  # A submission has no reviewed state, so this is what is running rather than
  # what is waiting — SPEC-0048 invariant 8.
  test "collaboration counts published cases, open milestones, and submissions" do
    business_case = @organization.business_cases.create!(owner: @owner, title: "Routing Costs",
                                                         brief: "Cut the cost of the evening run",
                                                         requirements: "Weekly check-in")
    business_case.milestones.create!(title: "Baseline the route")
    business_case.transition_to!("published", actor: @owner)

    collaboration = Recruitment::CompanyDashboard.call(organization: @organization,
                                                       viewer: @owner)[:collaboration]

    assert_equal 1, collaboration.published_cases
    assert_equal 1, collaboration.open_milestones
    assert_equal 0, collaboration.submissions
  end

  test "an organization that is not active has no work surface at all" do
    @organization.update!(status: "suspended")

    assert_nil Recruitment::CompanyDashboard.call(organization: @organization, viewer: @owner)
  end

  private
    def queue(viewer, key)
      Recruitment::CompanyDashboard.call(organization: @organization, viewer:)[:queues]
                                   .find { |candidate| candidate.key == key }
    end

    def submitted_request_for(student)
      request = @organization.internship_requests.create!(student:, motivation: "Your routing work",
                                                          learning_goals: "Optimisation")
      request.submit!(actor: student)
      request
    end

    def active_placement_for(student)
      request = submitted_request_for(student)
      request.approve!(actor: @owner)
      placement = InternshipPlacement.from_request!(request, actor: @owner)
      placement.activate!(actor: @owner)
      placement
    end

    def published_job
      job = @organization.job_posts.create!(creator: @owner, title: "Work Job", summary: "Summary",
                                            description: "Description", category: "Product",
                                            department: "Academy", team: "Platform", seniority: "Junior",
                                            location: "Bangkok")
      job.transition_to!("review")
      job.transition_to!("published")
      job
    end

    def application_for(job, index)
      candidate = User.create!(name: "Work Candidate #{index}", student_id: "301107174#{index.to_s.rjust(4, '0')}",
                               password: "SafePassword#{index}1")
      CandidateProfile.create!(user: candidate, application_data_reuse_consent: true)
      Recruitment::JobApplication.submit!(job_post: job, candidate:, statement: "Statement #{index}")
    end
end
