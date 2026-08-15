require "test_helper"

# INT-002 and INT-003 shipped the student's screens and no way to reach them:
# nothing in the app linked to /internship or to /internships/placements,
# so a learner had to type the URL. The door is the navigation entry, the two
# screens pointing at each other, and a running internship shown where the
# student actually arrives.
class StudentInternshipDoorTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student)
    @organization = Organization.create!(name: "Door Co", creator: users(:admin),
                                         accepts_internship_requests: true)
    @decider = users(:one)
    @organization.memberships.create!(user: @decider, role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
  end

  def nav_labels
    css_select(%(nav[aria-label="#{I18n.t("chrome.nav_label")}"] a)).map { it.text.strip }
  end

  test "every student is offered internships in the navigation, whether or not they have one" do
    sign_in_as @student
    get root_path

    assert_includes nav_labels, I18n.t("chrome.nav.internships")
    assert_equal "/internship", internship_requests_path
    assert_select "a[href=?]", internship_requests_path
  end

  test "the navigation entry opens the student's requests" do
    sign_in_as @student
    get internship_requests_path

    assert_response :success
    assert_select "h1", I18n.t("internship_requests.title")
  end

  test "the student internship door lists published opportunities" do
    program = @organization.internship_programs.create!(
      creator: @decider, mentor: users(:instructor), name: "Open AI Internship", department: "Innovation",
      description: "Build a reviewed prototype.", duration_weeks: 8, max_students: 3,
      required_skills: "Communication", learning_outcomes: "Ship a prototype", working_days: "Weekdays",
      remote_policy: "hybrid", certificate_policy: "Certificate", equipment_provided: "Laptop"
    )
    program.transition_to!("review")
    program.transition_to!("published")

    sign_in_as @student
    get internship_requests_path

    assert_response :success
    assert_select "a[href=?]", recruitment_internship_path(program), text: "Open AI Internship"
  end

  # The screen moved from /internship-requests to /internship on 2026-08-16.
  # A bookmark made before that is still somebody's way in.
  test "the door's former address still arrives at the door" do
    sign_in_as @student

    get "/internship-requests"

    assert_response :moved_permanently
    assert_redirected_to internship_requests_path
  end

  test "the former address carries a deeper path across with it" do
    request = @student.internship_requests.create!(organization: @organization,
                                                   motivation: "I want to learn.",
                                                   learning_goals: "Ship something real.")
    sign_in_as @student

    get "/internship-requests/#{request.id}"

    assert_response :moved_permanently
    assert_redirected_to internship_request_path(request)
  end

  # Ranking is inserted relative to the end of the list, so adding an entry
  # there is exactly the kind of change that moves it silently.
  test "the ranking entry keeps its place after progress" do
    feature_settings(:leaderboard).update!(enabled: true)

    sign_in_as @student
    get root_path

    labels = nav_labels
    assert_equal labels.index(I18n.t("chrome.nav.progress")) + 1,
                 labels.index(I18n.t("chrome.nav.ranking"))
  end

  test "a running internship is shown on the door, with the week that is missing" do
    placement = active_placement

    sign_in_as @student
    get internship_requests_path

    assert_response :success
    assert_select "a[href=?]", internship_placement_path(placement)
    assert_select "a[href=?]", internship_placements_path
    assert_select "span", I18n.t("internship_placements.week_missing")
  end

  test "the week's prompt disappears once the report is written" do
    placement = active_placement
    placement.progress_reports.create!(activities: "Mapped the evening routes")

    sign_in_as @student
    get internship_requests_path

    assert_response :success
    assert_select "span", { text: I18n.t("internship_placements.week_missing"), count: 0 }
  end

  test "a student with no internship sees no internships section" do
    sign_in_as @student
    get internship_requests_path

    assert_response :success
    assert_select "h2", { text: I18n.t("internship_placements.mine_heading"), count: 0 }
  end

  test "the placements screen points back at requests for a student" do
    active_placement

    sign_in_as @student
    get internship_placements_path

    assert_response :success
    assert_select "a[href=?]", internship_requests_path
  end

  # The company reaches its own queue from its work surface; /internship
  # is student-only and would 404 for them.
  test "the placements screen offers a company member no student-only link" do
    active_placement

    sign_in_as @decider
    get internship_placements_path

    assert_response :success
    assert_select "a[href=?]", internship_requests_path, count: 0
  end

  private
    def active_placement
      request = @organization.internship_requests.create!(student: @student, motivation: "Your routing work",
                                                          learning_goals: "Optimisation")
      request.submit!(actor: @student)
      request.approve!(actor: @decider)
      placement = InternshipPlacement.from_request!(request, actor: @decider)
      placement.activate!(actor: @decider)
      placement
    end
end
