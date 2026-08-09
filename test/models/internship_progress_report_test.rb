require "test_helper"

class InternshipProgressReportTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Report Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    request = @organization.internship_requests.create!(student: users(:student), motivation: "x",
                                                       learning_goals: "y")
    request.submit!(actor: users(:student))
    request.approve!(actor: users(:one))
    @placement = InternshipPlacement.from_request!(request, actor: users(:one))
    @placement.activate!(actor: users(:one))
  end

  test "a report defaults to the current week and normalizes its text" do
    report = @placement.progress_reports.create!(activities: "  Mapped the routes  ", hours: 32.5)

    assert_equal "Mapped the routes", report.activities
    assert_equal Date.current.beginning_of_week, report.week_starting_on
    assert_predicate report.submitted_at, :present?
    assert_in_delta 32.5, report.hours.to_f, 0.01
    assert_not_predicate report, :acknowledged?
  end

  test "the week must be a Monday and cannot be in the future" do
    assert_not @placement.progress_reports.build(activities: "x",
                                                week_starting_on: Date.current.beginning_of_week + 2).valid?
    assert_not @placement.progress_reports.build(activities: "x",
                                                week_starting_on: Date.current.beginning_of_week + 7).valid?
    assert @placement.progress_reports.build(activities: "x",
                                            week_starting_on: Date.current.beginning_of_week - 7).valid?
  end

  test "one report per placement per week" do
    @placement.progress_reports.create!(activities: "First pass")
    duplicate = @placement.progress_reports.build(activities: "Second pass")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:week_starting_on], :any?

    assert_raises(ActiveRecord::RecordNotUnique) do
      @placement.progress_reports.build(activities: "Racing", week_starting_on: Date.current.beginning_of_week,
                                       submitted_at: Time.current).save!(validate: false)
    end
  end

  test "reports are append-only and an acknowledgement never rewrites them" do
    report = @placement.progress_reports.create!(activities: "Original week")

    assert_not report.destroy
    report.acknowledge!(actor: users(:one))

    assert_predicate report, :acknowledged?
    assert_equal users(:one), report.acknowledged_by
    assert_equal "Original week", report.reload.activities
    assert_raises(ActiveRecord::RecordInvalid) { report.acknowledge!(actor: users(:one)) }
  end

  test "only a company decider may acknowledge" do
    report = @placement.progress_reports.create!(activities: "Original week")

    [ users(:instructor), users(:student), users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid, "#{actor.name} must not acknowledge") do
        report.acknowledge!(actor:)
      end
    end

    assert_not_predicate report.reload, :acknowledged?
  end

  test "a placement that is not active accepts no reports" do
    planned = planned_placement_for(users(:two))
    assert_not planned.progress_reports.build(activities: "Too early").valid?

    @placement.complete!(actor: users(:one))
    assert_not @placement.progress_reports.build(activities: "Too late").valid?
  end

  test "hours stay inside a plausible week and text inside the boundary" do
    assert_not @placement.progress_reports.build(activities: "x", hours: -1).valid?
    assert_not @placement.progress_reports.build(activities: "x", hours: 169).valid?
    assert_not @placement.progress_reports.build(activities: " ").valid?
    assert_not @placement.progress_reports.build(activities: "x" * 5_001).valid?
  end

  test "the model records privacy-safe audit evidence for every report" do
    assert_difference "AuditEvent.count", 1 do
      @placement.progress_reports.create!(activities: "Confidential client notes")
    end

    audit = AuditEvent.order(:id).last

    assert_equal users(:student), audit.user
    assert_equal "internship_progress_report_submitted", audit.action
    assert_equal @organization.name, audit.params["organization"]
    assert_not audit.params.values.any? { |value| value.to_s.include?("Confidential client notes") }
    assert_predicate audit.text, :present?
  end

  test "reporting never writes to academic records or the shipped internship domain" do
    assert_no_difference [ "Enrollment.count", "Submission.count", "TopicCompletion.count",
                           "Recruitment::InternshipEvaluation.count" ] do
      @placement.progress_reports.create!(activities: "Week of work", hours: 40)
    end
  end

  private
    def planned_placement_for(student)
      request = @organization.internship_requests.create!(student:, motivation: "x", learning_goals: "y")
      request.submit!(actor: student)
      request.approve!(actor: users(:one))
      InternshipPlacement.from_request!(request, actor: users(:one))
    end
end
