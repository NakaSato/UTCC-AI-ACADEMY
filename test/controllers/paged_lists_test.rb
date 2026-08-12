require "test_helper"

# The screens SPEC-0051 names as paged, asserted by growing the data rather than
# by reading the code: a list the specification pages renders at most one page of
# rows however many rows exist.
#
# Every list here was previously unbounded. The audit log was worse than
# unbounded — it took the most recent fifty and the older half was unreachable —
# so it is asserted twice: once for the page, and once for the history that
# nothing linked to before ADR-0050.
class PagedListsTest < ActionDispatch::IntegrationTest
  SIZE = Page::SIZE

  # One constant, one place (ADR-0050 decision 4). A screen may pass its own with
  # a sentence saying why; if this number moves, it moves for all of them.
  test "a page is twenty-five rows" do
    assert_equal 25, Page::SIZE
  end

  # ---- The admin console ----------------------------------------------------

  test "the roster pages, and the last page holds the remainder" do
    admin = users(:admin)
    extra = 8
    (SIZE + extra - User.count).times { create_learner }
    sign_in_as admin

    get admin_url(tab: :users)
    assert_response :success
    assert_select "[data-user-id]", SIZE

    get admin_url(tab: :users, page: 2)
    assert_response :success
    assert_select "[data-user-id]", User.count - SIZE
  end

  test "a roster page keeps the role filter, and changing the filter starts again at page one" do
    sign_in_as users(:admin)
    (SIZE + 2).times { create_learner }

    get admin_url(tab: :users, role: :student, page: 2)

    assert_response :success
    assert_select "nav[aria-label=?] a[href*=?]", I18n.t("pagination.label"), "role=student"
    # The chips carry no page, so a filter change lands on page 1 rather than on
    # a page that exists under a filter the reader is no longer using.
    assert_select "a[href*=?]", "role=instructor" do |links|
      assert(links.none? { it["href"].include?("page=") }, "a filter chip carried a page number")
    end
  end

  test "the audit log pages instead of truncating, and the fiftieth row back is reachable" do
    admin = users(:admin)
    AuditEvent.delete_all
    oldest = AuditEvent.create!(user: admin, action: "enrolled", params: { name: "x", label: "y" },
                                created_at: 3.years.ago)
    59.times { AuditEvent.create!(user: admin, action: "enrolled", params: { name: "x", label: "y" }) }
    sign_in_as admin

    get admin_url(tab: :audit)
    assert_response :success
    assert_select "[data-audit-event-id]", SIZE
    assert_select "[data-audit-event-id=?]", oldest.id.to_s, false, "the oldest row is not on the first page"

    get admin_url(tab: :audit, page: 3)
    assert_response :success
    assert_select "[data-audit-event-id=?]", oldest.id.to_s
  end

  test "an audit page keeps the level filter" do
    admin = users(:admin)
    AuditEvent.delete_all
    (SIZE + 1).times { AuditEvent.create!(user: admin, action: "role_changed", params: { name: "x", role: "admin" }) }
    sign_in_as admin

    get admin_url(tab: :audit, level: :warn, page: 2)

    assert_response :success
    assert_select "[data-audit-event-id]", 1
    assert_select "nav[aria-label=?] a[href*=?]", I18n.t("pagination.label"), "level=warn"
  end

  test "the proposals tab pages" do
    (SIZE + 1).times { |index| create_proposal(index) }
    sign_in_as users(:admin)

    get admin_url(tab: :proposals)
    assert_response :success
    assert_select "[data-proposal-id]", SIZE

    get admin_url(tab: :proposals, page: 2)
    assert_select "[data-proposal-id]", 1
  end

  test "the approval queue pages" do
    (SIZE + 1).times { |index| create_approval_request(index) }
    sign_in_as users(:admin)

    get admin_url(tab: :queue)
    assert_response :success
    assert_select "[data-approval-request-id]", SIZE

    get admin_url(tab: :queue, page: 2)
    assert_select "[data-approval-request-id]", 1
  end

  # ---- Academic posts -------------------------------------------------------

  test "the posts an author can reach page" do
    author = users(:instructor)
    (SIZE + 3).times { |index| AcademicPost.create!(owner: author, title: "Post #{index}") }
    sign_in_as author

    get academic_posts_url
    assert_response :success
    assert_select "[data-academic-post-id]", SIZE

    get academic_posts_url(page: 2)
    assert_select "[data-academic-post-id]", 3
  end

  # ---- Recruitment ----------------------------------------------------------

  test "the public job search pages, and a page keeps the search" do
    organization = create_organization
    (SIZE + 2).times { |index| publish_job(organization, "Bangkok Engineer #{index}") }
    sign_in_as users(:student)

    get recruitment_jobs_url
    assert_response :success
    assert_select "[data-job-post-id]", SIZE

    get recruitment_jobs_url(query: "bangkok", page: 2)
    assert_response :success
    assert_select "[data-job-post-id]", 2
    assert_select "nav[aria-label=?] a[href*=?]", I18n.t("pagination.label"), "query=bangkok"
  end

  test "a company's postings page" do
    organization = create_organization
    owner = organization.memberships.active.first.user
    (SIZE + 1).times { |index| organization.job_posts.create!(creator: owner, title: "Draft #{index}") }
    sign_in_as owner

    get company_job_posts_url(organization)
    assert_response :success
    assert_select "[data-job-post-id]", SIZE

    get company_job_posts_url(organization, page: 2)
    assert_select "[data-job-post-id]", 1
  end

  test "a posting's applications page" do
    organization = create_organization
    reviewer = organization.memberships.active.first.user
    job = publish_job(organization, "Reviewed role")
    (SIZE + 1).times { apply_to(job) }
    sign_in_as reviewer

    get company_job_post_applications_url(organization, job)
    assert_response :success
    assert_select "[data-application-id]", SIZE

    get company_job_post_applications_url(organization, job, page: 2)
    assert_select "[data-application-id]", 1
  end

  test "a candidate's own applications page" do
    organization = create_organization
    candidate = users(:student)
    CandidateProfile.create!(user: candidate, application_data_reuse_consent: true)
    (SIZE + 1).times do |index|
      job = publish_job(organization, "Role #{index}")
      Recruitment::JobApplication.submit!(job_post: job, candidate:, statement: "Statement")
    end
    sign_in_as candidate

    get recruitment_job_applications_url
    assert_response :success
    assert_select "[data-application-id]", SIZE

    get recruitment_job_applications_url(page: 2)
    assert_select "[data-application-id]", 1
  end

  # ---- The URL a person edited ----------------------------------------------

  test "an impossible page renders the nearest real page rather than a 404 or an empty screen" do
    author = users(:instructor)
    (SIZE + 1).times { |index| AcademicPost.create!(owner: author, title: "Post #{index}") }
    sign_in_as author

    [ "0", "-1", "abc", "99" ].each do |number|
      get academic_posts_url(page: number)

      assert_response :success, "?page=#{number} did not render"
      assert_select "[data-academic-post-id]", minimum: 1, message: "?page=#{number} rendered an empty list"
    end

    get academic_posts_url(page: 99)
    assert_select "[data-academic-post-id]", 1, "a page past the end must hold the last page's rows"
  end

  test "a list that fits on one page renders no control" do
    sign_in_as users(:instructor)
    AcademicPost.create!(owner: users(:instructor), title: "The only post")

    get academic_posts_url

    assert_response :success
    assert_select "nav[aria-label=?]", I18n.t("pagination.label"), false,
      "a pagination control on a list of one is noise"
  end

  # The control is a nav a keyboard can use, and the current page says so.
  test "the control names itself, marks the current page, and links rather than posts" do
    author = users(:instructor)
    (SIZE + 1).times { |index| AcademicPost.create!(owner: author, title: "Post #{index}") }
    sign_in_as author

    get academic_posts_url(page: 2)

    assert_select "nav[aria-label=?]", I18n.t("pagination.label") do
      assert_select "a[aria-current=page]", text: "2"
      assert_select "a[rel=prev]", text: I18n.t("pagination.previous")
      assert_select "button", false, "a page link is a link, not a button"
    end
  end

  private
    def create_learner
      User.create!(name: "Learner #{User.count}", student_id: "99#{format('%011d', User.count)}",
                   password: "loadTest#{User.count}9")
    end

    def create_proposal(index)
      ProposalRequest.create!(user: users(:one), title: "Proposal #{index}", category: "feature",
                              problem: "A problem worth stating.", idea: "An idea worth reading.",
                              impact: "An outcome worth having.")
    end

    def create_approval_request(index)
      course = Course.create!(code: "PG#{format('%04d', index)}", position: 900 + index, level: "beginner",
                              credits: 3, projects: 1, hours: 30, learners: 0, rating: 0,
                              lifecycle_state: "draft")
      ApprovalRequest.create_course_lifecycle!(course:, requester: users(:admin), to_state: "published")
    end

    def create_organization
      organization = Organization.create!(name: "Paged Org", creator: users(:admin))
      organization.memberships.create!(user: users(:console_company), role: "owner")
      organization
    end

    def publish_job(organization, title)
      job = organization.job_posts.create!(creator: organization.memberships.active.first.user, title:,
                                           summary: "Summary", description: "Description", category: "Product",
                                           department: "Academy", team: "Platform", seniority: "Junior",
                                           location: "Bangkok")
      job.transition_to!("review")
      job.transition_to!("published")
      job
    end

    def apply_to(job)
      candidate = User.create!(name: "Applicant #{User.count}", student_id: "99#{format('%011d', User.count)}",
                               password: "loadTest#{User.count}9")
      CandidateProfile.create!(user: candidate, application_data_reuse_consent: true)
      Recruitment::JobApplication.submit!(job_post: job, candidate:, statement: "Statement")
    end
end
