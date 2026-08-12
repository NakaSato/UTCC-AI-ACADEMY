require "test_helper"

class InternshipPlacementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Placement Controller Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @approved_request = approved_request_for(users(:student))
  end

  test "a decider creates a placement from an approved request and runs its lifecycle" do
    sign_in_as users(:one)

    get internship_placements_path
    assert_response :success
    assert_includes response.body, I18n.t("internship_placements.placeable_heading")
    assert_includes response.body, users(:student).name

    assert_difference [ "InternshipPlacement.count", "AuditEvent.count" ], 1 do
      post internship_placements_path, params: { internship_request_id: @approved_request.id }
    end

    placement = InternshipPlacement.order(:id).last
    assert_redirected_to internship_placement_path(placement)
    assert_predicate placement, :planned?

    assert_difference [ "AuditEvent.count", "Notification.count" ], 1 do
      post activate_internship_placement_path(placement)
    end
    assert_predicate placement.reload, :active?

    post complete_internship_placement_path(placement)
    assert_predicate placement.reload, :completed?

    notification = users(:student).notifications.order(:id).last
    assert_equal "internship_placement_updated", notification.kind
    assert_equal internship_placement_path(placement), notification.action_path
  end

  test "the same approved request cannot be placed twice" do
    sign_in_as users(:one)
    post internship_placements_path, params: { internship_request_id: @approved_request.id }

    assert_no_difference "InternshipPlacement.count" do
      post internship_placements_path, params: { internship_request_id: @approved_request.id }
    end
    assert_redirected_to internship_placements_path
  end

  test "a mentor, a student, and an admin cannot create or advance a placement" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    [ users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      assert_no_difference "InternshipPlacement.count" do
        post internship_placements_path, params: { internship_request_id: @approved_request.id }
      end

      post activate_internship_placement_path(placement)
      assert_response :not_found
      assert_predicate placement.reload, :planned?

      sign_out
    end

    # An unassigned instructor cannot open it at all. An administrator can,
    # since assigning the supervisor happens on this screen — and reads no week
    # of it, which `internship_faculty_assignments_controller_test` covers.
    sign_in_as users(:instructor)
    get internship_placement_path(placement)
    assert_response :not_found
    sign_out

    sign_in_as users(:admin)
    get internship_placement_path(placement)
    assert_response :success
  end

  test "the placed student reads the placement, submits a week, and cannot advance it" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))
    placement.activate!(actor: users(:one))

    sign_in_as users(:student)

    get internship_placement_path(placement)
    assert_response :success
    assert_includes response.body, I18n.t("internship_placements.evidence_notice")

    assert_difference [ "InternshipProgressReport.count", "AuditEvent.count" ], 1 do
      post reports_internship_placement_path(placement), params: {
        progress_report: { activities: "Mapped the upcountry routes", hours: "32.5" }
      }
    end
    assert_redirected_to internship_placement_path(placement)

    # A second report for the same week is refused, not silently accepted.
    assert_no_difference "InternshipProgressReport.count" do
      post reports_internship_placement_path(placement), params: {
        progress_report: { activities: "Second attempt this week" }
      }
    end

    post complete_internship_placement_path(placement)
    assert_response :not_found
    assert_predicate placement.reload, :active?
  end

  test "a decider acknowledges a report without changing it" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))
    placement.activate!(actor: users(:one))
    report = placement.progress_reports.create!(activities: "Original week")

    sign_in_as users(:one)

    assert_difference [ "AuditEvent.count", "Notification.count" ], 1 do
      post acknowledge_report_internship_placement_path(placement, report_id: report.id)
    end

    assert_redirected_to internship_placement_path(placement)
    assert_predicate report.reload, :acknowledged?
    assert_equal users(:one), report.acknowledged_by
    assert_equal "Original week", report.activities
  end

  test "a student cannot submit a report on someone else's placement" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))
    placement.activate!(actor: users(:one))

    sign_in_as users(:two)

    assert_no_difference "InternshipProgressReport.count" do
      post reports_internship_placement_path(placement), params: {
        progress_report: { activities: "Not my internship" }
      }
    end
    assert_response :not_found
  end

  test "an accepted application stays placeable after a request-origin placement exists" do
    application = accepted_application_for(users(:two))
    InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    sign_in_as users(:one)
    get internship_placements_path

    assert_response :success
    assert_includes response.body, I18n.t("internship_placements.origin.application"),
      "a NULL application_id on the request-origin placement must not empty the placeable list"

    assert_difference "InternshipPlacement.count", 1 do
      post internship_placements_path, params: { application_id: application.id }
    end

    placement = InternshipPlacement.order(:id).last
    assert_equal application, placement.origin
    assert_equal users(:two), placement.student
  end

  test "the student's decision notification reads in the student's own language" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    sign_in_as users(:one)
    post activate_internship_placement_path(placement)

    notification = users(:student).notifications.order(:id).last
    assert_equal "active", notification.params["outcome"], "the row stores the key, not a sentence"
    I18n.with_locale(:th) do
      assert_includes notification.text, I18n.t("internship_placements.status.active", locale: :th)
    end
    I18n.with_locale(:en) do
      assert_includes notification.text, I18n.t("internship_placements.status.active", locale: :en)
    end
  end

  private
    def accepted_application_for(student)
      program = @organization.internship_programs.create!(
        creator: users(:one), mentor: users(:one), name: "Logistics Internship", department: "Ops",
        description: "Work with the routing team.", required_skills: "Spreadsheets",
        learning_outcomes: "Cost analysis", working_days: "Mon-Fri", certificate_policy: "On completion"
      )
      program.transition_to!("review")
      program.transition_to!("published")
      application = program.apply!(student:, statement: "Ready to learn")
      application.accept!(reviewer: users(:one))
      application
    end

    def approved_request_for(student)
      request = @organization.internship_requests.create!(student:, motivation: "Your routing work",
                                                        learning_goals: "Optimisation")
      request.submit!(actor: student)
      request.approve!(actor: users(:one))
      request
    end
end
