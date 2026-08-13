require "test_helper"

# The screens that fold a whole cohort must cost the same whether the cohort is
# seven students or seventy. Nothing on screen changes when that stops being
# true — the page just gets slower — so it is asserted here rather than noticed
# in production, where the app is one Puma process and one slow page is the box.
#
# InstructorReport used to build a LearnerProgress per roster row, which cost
# three queries a student and made /instructor 3n + 12.
class QueryBudgetTest < ActiveSupport::TestCase
  setup do
    @section = sections(:ba_2)
    @course = @section.course
    @topics = Topic.order(:id).limit(4).to_a
  end

  def count_queries
    count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
      next if payload[:sql] =~ /\A\s*(BEGIN|COMMIT|RELEASE|SAVEPOINT)/i
      count += 1
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  # 13 digits exactly — User validates the format, so a shorter or longer
  # sequence fails validation rather than the assertion you meant to make.
  def next_student_id = "99#{format('%011d', User.count)}"

  def enrol(count)
    count.times do
      user = User.create!(name: "Load #{User.count}", student_id: next_student_id,
                          password: "loadTest#{User.count}9")
      Enrollment.create!(user:, section: @section)
      @topics.first(3).each do |topic|
        TopicCompletion.create!(user:, course: @course, topic:, learned_at: 2.days.ago)
      end
    end
  end

  test "the instructor report costs the same for a large section as a small one" do
    enrol(3)
    # Warm Current.syllabus first — it is memoised for the length of a request,
    # so an unwarmed first call pays for the taxonomy and makes the comparison
    # measure the memo rather than the roster.
    InstructorReport.new(@section).roster
    small = count_queries { InstructorReport.new(@section).roster }

    enrol(30)
    large = count_queries { InstructorReport.new(@section).roster }

    assert_equal small, large,
      "roster went from #{small} to #{large} queries when the section grew — a per-student query is back"
  end

  # The figures have to survive the optimisation, not just the query count.
  test "the roster still reports each student's own progress" do
    enrol(2)
    report = InstructorReport.new(@section)
    newcomer = report.roster.find { it.name.start_with?("Load") }

    assert_equal (3 * 100.0 / Syllabus.topic_count).round, newcomer.percent
    assert_equal @section.students.count, report.size
  end

  test "a student with nothing recorded is on the roster at zero rather than missing" do
    user = User.create!(name: "Silent", student_id: next_student_id, password: "silentOne1")
    Enrollment.create!(user:, section: @section)

    row = InstructorReport.new(@section).roster.find { it.name == "Silent" }

    assert_not_nil row, "a student with no completions must still appear"
    assert_equal 0, row.percent
    assert_nil row.seen
  end

  # Seven chips, one read. Asserted against the cost of a single `all` rather
  # than a bare number, so the taxonomy's own queries do not have to be counted
  # here and the test stays about the loop.
  test "the catalog reads the courses table once per render, not once per filter chip" do
    CourseCatalog.all # warm Current.syllabus

    assert_equal count_queries { CourseCatalog.all }, count_queries { CourseCatalog.filter_counts }
  end

  test "standings is counted once per request however often a rank is asked for" do
    user = users(:student)
    TopicCompletion.create!(user:, course: @course, topic: @topics.first, learned_at: 1.day.ago)

    first = count_queries { LearnerProgress.standings }
    again = count_queries { LearnerProgress.standings }

    assert_equal 2, first, "two grouped counts on the first ask"
    assert_equal 0, again, "and none on the second"
  end

  test "recording a completion invalidates the memoised standings" do
    LearnerProgress.standings
    TopicCompletion.record(user: users(:student), course_code: @course.code,
                           topic_key: @topics.first.key, kind: :learned)

    assert_equal 2, count_queries { LearnerProgress.standings },
      "a new completion changes the ranking, so the memo must be dropped"
  end

  # A deliverable's reader is a membership lookup, so asking per file cost two
  # queries a file and grew with the pile. The company sees the whole list, so
  # this is the reader who pays for it.
  test "reading an internship's deliverables costs the same however many there are" do
    placement = active_placement
    decider = placement.organization.memberships.active.first.user

    add_deliverables(placement, 1)
    placement.deliverables_readable_by(decider).to_a
    small = count_queries { placement.deliverables_readable_by(decider).to_a }

    add_deliverables(placement, 9)
    large = count_queries { placement.deliverables_readable_by(decider).to_a }

    assert_equal small, large,
      "deliverables went from #{small} to #{large} queries when the pile grew — a per-file check is back"
  end

  # ADR-0048 said four counts run on each page load, and that if that stopped
  # being true the fix was caching rather than fewer numbers. It was already
  # untrue when it was written: the four are the dashboard's own, and underneath
  # them OrganizationReporting was counting once per status across two
  # vocabularies of six and seven. Every number on the board survived; they are
  # asked for in grouped counts now, so a new status costs nothing.
  test "the company work surface costs the same however many applicants there are" do
    organization = active_placement.organization
    viewer = organization.memberships.active.first.user
    job = published_job(organization)

    apply_to(job, 2)
    Recruitment::CompanyDashboard.call(organization:, viewer:)
    small = count_queries { Recruitment::CompanyDashboard.call(organization:, viewer:) }

    apply_to(job, 20)
    large = count_queries { Recruitment::CompanyDashboard.call(organization:, viewer:) }

    assert_equal small, large,
      "the work surface went from #{small} to #{large} queries as applications arrived"
    assert_operator large, :<=, 13,
      "the work surface now costs #{large} queries, up from 13; a per-status count is probably back"
  end

  # The budget counts queries, not rows, which is why every screen here could
  # pass while rendering ten thousand of them. Paging is the bound on the other
  # axis, and it is only worth having if reaching for it costs one more query —
  # the count — rather than one per row (ADR-0050 decision 5).
  test "a paged list costs one query more than an unpaged one, whatever the row count" do
    AuditEvent.delete_all
    record_events(Page::SIZE + 5)
    scope = AuditEvent.newest_first

    whole = count_queries { scope.to_a }
    paged = count_queries { Page.new(scope, 1).records }

    assert_equal whole + 1, paged, "a page is the rows and the count, and nothing else"

    record_events(Page::SIZE * 4)

    assert_equal paged, count_queries { Page.new(scope, 1).records },
      "the page's query count moved when the list grew"
  end

  # Nearly every screen asks whether a flag is on — the header, the footer, the
  # nav, the bell, two admin tabs — and each ask used to be its own `find_by`.
  # The feature-control tab ran forty-six identical single-row queries in one
  # render, because `admin_rows` asked once per key inside a loop that ran once
  # per flag, and the chrome asked again on the way past.
  #
  # Three rows. One query, then none, for the length of a request.
  test "the feature flags are read once however often they are asked for" do
    Current.feature_settings = nil

    first = count_queries { FeatureSetting.enabled?(:search) }
    again = count_queries do
      20.times { FeatureSetting.enabled?(:notifications) }
      AdminConsole.flags
      AdminConsole.flags_off
    end

    assert_equal 1, first, "the first ask reads the table"
    assert_equal 0, again, "and nothing after it does"
  end

  # The same contract the standings memo carries: a write invalidates it, so the
  # screen that flipped a flag does not render the value it flipped away from.
  # Held by a model callback rather than by the writer remembering, because a
  # console session and a test both write without asking the class method.
  test "changing a flag invalidates the memo, however it was changed" do
    FeatureSetting.enabled?(:leaderboard) # warm
    FeatureSetting.find_by!(key: "leaderboard").update!(enabled: true)

    # Counted around the assertion rather than after it: the ask that proves the
    # value is also the ask that refills the memo, so measuring afterwards would
    # measure the refill and report zero however stale the answer was.
    reads = count_queries { assert FeatureSetting.enabled?(:leaderboard), "the memo outlived the write" }

    assert_equal 1, reads, "the write left the memo in place, so the table was never re-read"
  end

  # The roster prints a control per row that asks whether the account has console
  # access, and that question is a membership lookup. It was one query per row —
  # twenty-five on a full page — because `.active` on an association builds a
  # fresh relation and goes back to the database however loaded the rows are.
  #
  # Folded in Ruby now, so a screen that preloads pays once for everybody. The
  # cohort is loaded once, never once per member.
  test "asking a preloaded account about company membership costs nothing" do
    organization = Organization.create!(name: "Preload Co", creator: users(:admin))
    organization.memberships.create!(user: users(:console_company), role: "owner")

    accounts = User.includes(:organization_memberships).order(:id).to_a

    assert_equal 0, count_queries { accounts.each(&:console_access?) },
      "a preloaded roster went back to the database per row"
    assert accounts.find { it == users(:console_company) }.company_member?
    assert_not accounts.find { it == users(:two) }.company_member?
  end

  private
    def record_events(count)
      count.times do
        AuditEvent.create!(user: users(:admin), action: "enrolled", params: { name: "x", label: "y" })
      end
    end

    def published_job(organization)
      job = organization.job_posts.create!(creator: organization.memberships.active.first.user,
                                           title: "Budget Job", summary: "Summary", description: "Description",
                                           category: "Product", department: "Academy", team: "Platform",
                                           seniority: "Junior", location: "Bangkok")
      job.transition_to!("review")
      job.transition_to!("published")
      job
    end

    def apply_to(job, count)
      count.times do
        candidate = User.create!(name: "Applicant #{User.count}", student_id: next_student_id,
                                 password: "loadTest#{User.count}9")
        CandidateProfile.create!(user: candidate, application_data_reuse_consent: true)
        Recruitment::JobApplication.submit!(job_post: job, candidate:, statement: "Statement")
      end
    end

    def active_placement
      organization = Organization.create!(name: "Budget Org", creator: users(:admin),
                                          accepts_internship_requests: true)
      organization.memberships.create!(user: users(:one), role: "owner")
      request = organization.internship_requests.create!(student: users(:student),
                                                         motivation: "Routing", learning_goals: "Measuring")
      request.submit!(actor: users(:student))
      request.approve!(actor: users(:one))
      placement = InternshipPlacement.from_request!(request, actor: users(:one))
      placement.activate!(actor: users(:one))
      placement
    end

    def add_deliverables(placement, count)
      count.times do |index|
        deliverable = placement.deliverables.new(title: "Work #{placement.deliverables.count + index}",
                                                 author: placement.student)
        deliverable.file.attach(io: StringIO.new("%PDF-1.4 x"), filename: "work.pdf",
                                content_type: "application/pdf")
        deliverable.save!
      end
    end
end
