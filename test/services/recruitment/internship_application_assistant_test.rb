require "test_helper"

class Recruitment::InternshipApplicationAssistantTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Internship Assistant Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:two), mentor: users(:instructor), name: "Assistant Internship", department: "Innovation",
      description: "Build with a team.", duration_weeks: 8, max_students: 3, required_skills: "Communication",
      learning_outcomes: "Ship a reviewed prototype.", working_days: "Monday to Friday", remote_policy: "hybrid",
      paid: false, certificate_policy: "Certificate after review", equipment_provided: "Laptop"
    )
    @program.transition_to!("review")
    @program.transition_to!("published")
    @application = @program.applications.create!(student: users(:student), statement: "I want to learn.")
  end

  test "returns private pending guidance to the applicant" do
    guidance = Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:student))

    assert_equal %w[ review_learning_outcomes review_required_skills prepare_questions wait_for_decision ], guidance.items.map(&:key)
    assert_equal "program.learning_outcomes", guidance.items.first.source
    assert_match "does not match, rank, accept, evaluate", guidance.uncertainty
  end

  test "changes guidance after acceptance and gives only reflection for terminal states" do
    @application.accept!(reviewer: users(:two))
    guidance = Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:student))
    assert_includes guidance.items.map(&:key), "plan_mentor_checkin"

    @application.withdraw!
    guidance = Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:student))
    assert_equal [ "record_outcome" ], guidance.items.map(&:key)
  end

  test "does not return guidance to a mentor or another student" do
    assert_nil Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:instructor))
    assert_nil Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:one))
  end

  test "does not return guidance for an anonymous viewer or an unsaved application" do
    assert_nil Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: nil)

    unsaved_application = Recruitment::InternshipApplication.new(status: "pending")
    assert_nil Recruitment::InternshipApplicationAssistant.call(application: unsaved_application, viewer: nil)
  end

  test "does not return guidance after the program organization is suspended" do
    program = Recruitment::InternshipProgram.includes(:organization).find(@program.id)
    program.organization
    program.organization.update!(status: "suspended")
    @application.program = program

    assert_nil Recruitment::InternshipApplicationAssistant.call(application: @application, viewer: users(:student))
  end
end
