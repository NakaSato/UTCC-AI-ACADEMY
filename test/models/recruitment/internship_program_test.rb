require "test_helper"

class Recruitment::InternshipProgramTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Internship Program Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.new(
      creator: users(:two), mentor: users(:instructor), name: "AI Product Internship",
      department: "Innovation", description: "Learn product discovery with a real team.", duration_weeks: 12,
      max_students: 2, required_skills: "Communication", learning_outcomes: "Deliver a tested prototype.",
      working_days: "Monday to Friday", remote_policy: "hybrid", paid: false,
      certificate_policy: "Certificate after evaluation", equipment_provided: "Laptop provided"
    )
  end

  test "publishes only a complete program with an organization mentor" do
    @program.save!
    @program.transition_to!("review")
    @program.transition_to!("published")

    assert_predicate @program, :published?
    assert @program.published_at
    assert_predicate @program, :accepting_applications?
  end

  test "rejects publication without a mentor or learning outcomes" do
    @program.mentor = nil
    @program.learning_outcomes = ""

    assert @program.save
    assert_raises(ActiveRecord::RecordInvalid) { @program.transition_to!("review") }
  end

  test "rejects a mentor outside the organization" do
    @program.mentor = users(:student)

    assert_not @program.valid?
    assert_predicate @program.errors[:mentor], :any?
  end

  test "capacity closes after the configured number of accepted applications" do
    @program.save!
    @program.transition_to!("review")
    @program.transition_to!("published")
    first = @program.applications.create!(student: users(:student), statement: "First")
    second_student = User.create!(name: "Second student", student_id: "2011071730999", password: "Student99")
    second = @program.applications.create!(student: second_student, statement: "Second")
    @program.reload

    first.accept!(reviewer: users(:one))
    second.accept!(reviewer: users(:one))

    assert_not_predicate @program.reload, :accepting_applications?
  end
end
