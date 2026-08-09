require "test_helper"

class InternshipPlacementTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Placement Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @approved_request = approved_request_for(users(:student))
  end

  test "a placement comes from an approved request and starts planned" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    assert_predicate placement, :planned?
    assert_equal @organization, placement.organization
    assert_equal users(:student), placement.student
    assert_equal @approved_request, placement.origin
    assert_nil placement.application_id
  end

  test "a placement also comes from an accepted recruitment application" do
    application = accepted_application_for(users(:two))

    placement = InternshipPlacement.from_application!(application, actor: users(:one))

    assert_predicate placement, :planned?
    assert_equal users(:two), placement.student
    assert_equal application, placement.origin
    assert_nil placement.internship_request_id
  end

  test "creating a placement never mutates the application it came from" do
    application = accepted_application_for(users(:two))

    assert_no_changes -> { application.reload.attributes } do
      InternshipPlacement.from_application!(application, actor: users(:one))
    end
  end

  test "a placement needs exactly one origin" do
    application = accepted_application_for(users(:two))

    assert_not InternshipPlacement.new(organization: @organization, student: users(:student)).valid?
    both = InternshipPlacement.new(organization: @organization, student: users(:student),
                                   internship_request: @approved_request, application:)
    assert_not both.valid?
  end

  test "an unapproved origin cannot become a placement" do
    pending = @organization.internship_requests.create!(student: users(:two), motivation: "x", learning_goals: "y")

    assert_raises(ActiveRecord::RecordInvalid) { InternshipPlacement.from_request!(pending, actor: users(:one)) }
    assert_equal 0, InternshipPlacement.count
  end

  test "only a company decider may create a placement, and a failure leaves no row" do
    [ users(:instructor), users(:student), users(:admin) ].each do |actor|
      assert_no_difference "InternshipPlacement.count" do
        assert_raises(ActiveRecord::RecordInvalid, "#{actor.name} must not create a placement") do
          InternshipPlacement.from_request!(@approved_request, actor:)
        end
      end
    end
  end

  test "one placement per origin" do
    InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    assert_raises(ActiveRecord::RecordNotUnique) do
      InternshipPlacement.new(organization: @organization, student: users(:student),
                              internship_request: @approved_request).save!(validate: false)
    end
  end

  test "the lifecycle only advances through authorized transitions" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    placement.activate!(actor: users(:one))
    assert_predicate placement, :active?
    assert_predicate placement.activated_at, :present?
    assert_predicate placement, :accepts_reports?

    placement.complete!(actor: users(:one))
    assert_predicate placement, :completed?
    assert_predicate placement.completed_at, :present?
    assert_not placement.accepts_reports?

    assert_raises(ActiveRecord::RecordInvalid) { placement.activate!(actor: users(:one)) }
    assert_raises(ActiveRecord::RecordInvalid) { placement.cancel!(actor: users(:one), reason: "Too late") }
  end

  test "a placement cannot skip straight from planned to completed" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    assert_raises(ActiveRecord::RecordInvalid) { placement.complete!(actor: users(:one)) }
    assert_predicate placement.reload, :planned?
  end

  test "status never changes without a guarded transition" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))
    placement.status = "completed"

    assert_not placement.valid?
    assert_predicate placement.errors[:status], :any?
    assert_predicate placement.reload, :planned?
  end

  test "cancellation states a reason and is final" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    assert_raises(ActiveRecord::RecordInvalid) { placement.cancel!(actor: users(:one), reason: " ") }

    placement.cancel!(actor: users(:one), reason: "The team lost its supervisor")
    assert_predicate placement, :cancelled?
    assert_equal "The team lost its supervisor", placement.cancellation_reason
    assert_raises(ActiveRecord::RecordInvalid) { placement.complete!(actor: users(:one)) }
  end

  test "mentors and outsiders cannot advance a placement" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    [ users(:instructor), users(:student), users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid) { placement.activate!(actor:) }
    end

    assert_predicate placement.reload, :planned?
  end

  test "visibility is the placed student and the company deciders" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))

    assert placement.visible_to?(users(:student))
    assert placement.visible_to?(users(:one))

    [ users(:two), users(:instructor), users(:admin), nil ].each do |user|
      assert_not placement.visible_to?(user)
    end
  end

  test "a missing report for the current week is computed, not stored" do
    placement = InternshipPlacement.from_request!(@approved_request, actor: users(:one))
    assert_not placement.missing_current_week_report?, "a planned placement expects no report yet"

    placement.activate!(actor: users(:one))
    assert placement.missing_current_week_report?

    placement.progress_reports.create!(activities: "Mapped the routes")
    assert_not placement.reload.missing_current_week_report?
  end

  private
    def approved_request_for(student)
      request = @organization.internship_requests.create!(student:, motivation: "Your routing work",
                                                        learning_goals: "Optimisation")
      request.submit!(actor: student)
      request.approve!(actor: users(:one))
      request
    end

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
end
