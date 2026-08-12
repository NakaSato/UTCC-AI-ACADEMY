require "test_helper"

# The screens that carry ADR-0041 decisions 2 and 7: an administrator assigns a
# supervisor from the placement, the supervisor reads it and acknowledges its
# weeks, and nobody else gains anything.
class InternshipFacultyAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Faculty Co", creator: users(:admin),
                                         accepts_internship_requests: true)
    @decider = users(:one)
    @organization.memberships.create!(user: @decider, role: "owner")
    @student = users(:student)
    @faculty = users(:instructor)
    @placement = active_placement
  end

  # The same failure one step further out: an administrator supervises nothing
  # and hosts nothing, so every list on this screen was empty for them and the
  # placement they must assign a supervisor to could not be found at all.
  test "an administrator has a list of every internship, and which lack a supervisor" do
    sign_in_as users(:admin)
    get internship_placements_path

    assert_response :success
    assert_select "h2", I18n.t("internship_placements.administering_heading")
    assert_select "a[href=?]", internship_placement_path(@placement)
    assert_select "p", I18n.t("internship_placements.no_supervisor")
  end

  test "the list names the supervisor once one is assigned" do
    assign_faculty

    sign_in_as users(:admin)
    get internship_placements_path

    assert_response :success
    assert_select "p", I18n.t("internship_placements.supervised_by", name: @faculty.name)
    assert_select "p", { text: I18n.t("internship_placements.no_supervisor"), count: 0 }
  end

  test "nobody else is given the list of every internship" do
    [ @decider, @student, @faculty, users(:two) ].each do |actor|
      sign_in_as actor
      get internship_placements_path

      assert_response :success
      assert_select "h2", { text: I18n.t("internship_placements.administering_heading"), count: 0 },
                    "#{actor.identifier} must not be handed every internship in the university"
      sign_out
    end
  end

  test "the admin navigation carries the door to it" do
    sign_in_as users(:admin)
    get admin_path

    assert_response :success
    assert_select "a[href=?]", internship_placements_path
  end

  # Found by opening the screen rather than by posting to it: the one person
  # who may assign a supervisor could not reach the form.
  test "an administrator opens the placement to assign, and reads no week of it" do
    @placement.progress_reports.create!(activities: "Mapped the evening routes")

    sign_in_as users(:admin)
    get internship_placement_path(@placement)

    assert_response :success
    assert_select "form[action=?]", faculty_internship_placement_path(@placement)
    assert_select "p", I18n.t("internship_placements.reports_withheld")
    assert_select "body" do |body|
      assert_no_match(/Mapped the evening routes/, body.first.to_s,
                      "an administrator assigns a supervisor; the weeks are not theirs to read")
    end
  end

  test "an administrator assigns a supervisor and the student is told" do
    sign_in_as users(:admin)

    assert_difference -> { InternshipFacultyAssignment.active.count }, 1 do
      post faculty_internship_placement_path(@placement), params: { faculty_id: @faculty.id }
    end

    assert_redirected_to internship_placement_path(@placement)
    assert_equal @faculty, @placement.reload.supervisor
    assert_equal "internship_faculty_assigned", @student.notifications.newest_first.first.kind
  end

  test "nobody but an administrator may assign one" do
    [ @decider, @student, @faculty ].each do |actor|
      sign_in_as actor
      post faculty_internship_placement_path(@placement), params: { faculty_id: @faculty.id }

      assert_response :redirect
      assert_nil @placement.reload.supervisor, "#{actor.identifier} must not be able to assign a supervisor"
      sign_out
    end
  end

  test "a learner cannot be made a supervisor" do
    sign_in_as users(:admin)
    post faculty_internship_placement_path(@placement), params: { faculty_id: users(:two).id }

    assert_redirected_to internship_placement_path(@placement)
    assert_nil @placement.reload.supervisor
  end

  test "an administrator removes a supervisor and their reach closes with it" do
    assignment = assign_faculty
    sign_in_as users(:admin)

    delete revoke_faculty_internship_placement_path(@placement, assignment_id: assignment.id)

    assert_redirected_to internship_placement_path(@placement)
    assert_nil @placement.reload.supervisor

    sign_out
    sign_in_as @faculty
    get internship_placement_path(@placement)
    assert_response :not_found
  end

  test "the assigned supervisor opens the placement and sees the acknowledge control" do
    assign_faculty
    report = @placement.progress_reports.create!(activities: "Mapped the evening routes")

    sign_in_as @faculty
    get internship_placement_path(@placement)

    assert_response :success
    assert_select "form[action=?]", faculty_acknowledge_report_internship_placement_path(@placement, report_id: report.id)
    # The lifecycle stays the company's: no advancing control is offered.
    assert_select "form[action=?]", complete_internship_placement_path(@placement), count: 0
    assert_select "form[action=?]", activate_internship_placement_path(@placement), count: 0
  end

  test "an unassigned instructor cannot open a placement at all" do
    sign_in_as @faculty
    get internship_placement_path(@placement)

    assert_response :not_found
  end

  test "the supervisor acknowledges a week and the student's text is untouched" do
    assign_faculty
    report = @placement.progress_reports.create!(activities: "Mapped the evening routes")

    sign_in_as @faculty
    post faculty_acknowledge_report_internship_placement_path(@placement, report_id: report.id)

    assert_redirected_to internship_placement_path(@placement)
    report.reload
    assert_predicate report, :faculty_acknowledged?
    assert_not report.acknowledged?
    assert_equal "Mapped the evening routes", report.activities
  end

  test "an unassigned account cannot acknowledge as supervisor" do
    report = @placement.progress_reports.create!(activities: "Mapped the evening routes")

    [ @decider, @student, users(:admin_two) ].each do |actor|
      sign_in_as actor
      post faculty_acknowledge_report_internship_placement_path(@placement, report_id: report.id)

      assert_not report.reload.faculty_acknowledged?, "#{actor.identifier} is not the supervisor"
      sign_out
    end
  end

  test "the supervisor's placement list carries only what they were assigned" do
    other = active_placement(student: users(:two))
    assign_faculty

    sign_in_as @faculty
    get internship_placements_path

    assert_response :success
    assert_select "a[href=?]", internship_placement_path(@placement)
    assert_select "a[href=?]", internship_placement_path(other), count: 0
    assert_select "h2", I18n.t("internship_placements.supervising_heading")
  end

  test "the instructor navigation offers the internships they supervise" do
    sign_in_as @faculty
    get instructor_path

    assert_response :success
    assert_select "a[href=?]", internship_placements_path
  end

  private
    def active_placement(student: @student)
      request = @organization.internship_requests.create!(student:, motivation: "Your routing work",
                                                          learning_goals: "Optimisation")
      request.submit!(actor: student)
      request.approve!(actor: @decider)
      placement = InternshipPlacement.from_request!(request, actor: @decider)
      placement.activate!(actor: @decider)
      placement
    end

    def assign_faculty
      @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))
    end
end
