require "test_helper"

# ADR-0041 decisions 2 and 7, answered 2026-08-12: an administrator assigns one
# staff member to one placement; that assignment is what lets them read it and
# acknowledge its weeks, and it carries no gate over anybody.
class InternshipFacultyAssignmentTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Faculty Org", creator: users(:admin),
                                         accepts_internship_requests: true)
    @decider = users(:one)
    @organization.memberships.create!(user: @decider, role: "owner")
    @placement = active_placement_for(users(:student))
    @faculty = users(:instructor)
    Current.session = users(:admin).sessions.create!
  end

  teardown { Current.session = nil }

  test "an administrator assigns a staff member and the assignment is audited" do
    assert_difference -> { AuditEvent.where(action: "internship_faculty_assignment_created").count }, 1 do
      @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))
    end

    assert_equal @faculty, @placement.reload.supervisor
    assert @placement.supervised_by?(@faculty)
  end

  test "only an administrator may assign, and only staff may be assigned" do
    [ users(:one), users(:student), users(:instructor) ].each do |actor|
      assignment = @placement.faculty_assignments.new(faculty: @faculty, assigned_by: actor)
      assert_not assignment.valid?, "#{actor.identifier} is not an administrator and cannot assign"
    end

    learner = @placement.faculty_assignments.new(faculty: users(:two), assigned_by: users(:admin))
    assert_not learner.valid?, "a learner account cannot supervise an internship"
  end

  test "a placement has one supervisor at a time, and a revoked one frees the seat" do
    first = @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))

    second = @placement.faculty_assignments.new(faculty: users(:admin_two), assigned_by: users(:admin))
    assert_not second.valid?

    first.revoke!(actor: users(:admin))
    assert_predicate first, :revoked?
    assert @placement.faculty_assignments.new(faculty: users(:admin_two), assigned_by: users(:admin)).valid?
  end

  test "revocation is an administrator's act, is audited, and closes reading immediately" do
    assignment = @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))

    [ @decider, users(:student), @faculty ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid) { assignment.revoke!(actor:) }
    end

    assert_difference -> { AuditEvent.where(action: "internship_faculty_assignment_revoked").count }, 1 do
      assignment.revoke!(actor: users(:admin))
    end

    assert_not @placement.reload.supervised_by?(@faculty)
    assert_not @placement.visible_to?(@faculty)
  end

  # Decision 7: the assignment is the consent, so it is also the boundary.
  test "a supervisor reads their own placement and no other" do
    other = active_placement_for(users(:two))
    @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))

    assert @placement.visible_to?(@faculty)
    assert_not other.visible_to?(@faculty)
  end

  # Decision 2: read and acknowledge, no gate. The lifecycle stays the company's.
  test "a supervisor cannot advance, complete, or cancel the placement" do
    @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))

    assert_not @placement.manageable_by?(@faculty)
    assert_raises(ActiveRecord::RecordInvalid) { @placement.complete!(actor: @faculty) }
    assert_raises(ActiveRecord::RecordInvalid) { @placement.cancel!(actor: @faculty, reason: "No") }
    assert_predicate @placement.reload, :active?
  end

  test "a supervisor acknowledges a week without touching the company's acknowledgement" do
    @placement.faculty_assignments.create!(faculty: @faculty, assigned_by: users(:admin))
    report = @placement.progress_reports.create!(activities: "Mapped the evening routes")

    report.faculty_acknowledge!(actor: @faculty)

    assert_predicate report, :faculty_acknowledged?
    assert_equal @faculty, report.faculty_acknowledged_by
    assert_not report.acknowledged?, "the company's acknowledgement is a different fact"
    assert_raises(ActiveRecord::RecordInvalid) { report.faculty_acknowledge!(actor: @faculty) }

    report.acknowledge!(actor: @decider)
    assert_equal @decider, report.reload.acknowledged_by
    assert_equal @faculty, report.faculty_acknowledged_by
    assert_equal "Mapped the evening routes", report.activities
  end

  test "an unassigned account cannot acknowledge as supervisor" do
    report = @placement.progress_reports.create!(activities: "Mapped the evening routes")

    [ users(:instructor), users(:admin), @decider, users(:student) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid) { report.faculty_acknowledge!(actor:) }
    end
  end

  private
    def active_placement_for(student)
      request = @organization.internship_requests.create!(student:, motivation: "Your routing work",
                                                          learning_goals: "Optimisation")
      request.submit!(actor: student)
      request.approve!(actor: @decider)
      placement = InternshipPlacement.from_request!(request, actor: @decider)
      placement.activate!(actor: @decider)
      placement
    end
end
