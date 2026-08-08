require "test_helper"

class Recruitment::InternshipApplicationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Internship Application Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:two), mentor: users(:instructor), name: "Data Internship", department: "Data",
      description: "Learn with the data team.", duration_weeks: 8, max_students: 1,
      required_skills: "Curiosity", learning_outcomes: "Explain a data workflow.", working_days: "Weekdays",
      remote_policy: "remote", paid: true, certificate_policy: "Completion certificate",
      equipment_provided: "Remote setup support"
    )
    @program.transition_to!("review")
    @program.transition_to!("published")
  end

  test "allows one student application and prevents duplicates" do
    application = @program.applications.create!(student: users(:student), statement: "I want to learn.")
    duplicate = @program.applications.new(student: users(:student), statement: "Again")

    assert application.pending?
    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:student_id], :any?
  end

  test "students can withdraw their own pending application" do
    application = @program.applications.create!(student: users(:student), statement: "I want to learn.")

    application.withdraw!

    assert_predicate application.reload, :withdrawn?
  end

  test "a non-reviewer cannot be recorded as the decision maker" do
    application = @program.applications.create!(student: users(:student), statement: "I want to learn.")
    application.reviewed_by = users(:student)

    assert_not application.valid?
    assert_predicate application.errors[:reviewed_by], :any?
  end

  test "a suspended organization rejects application writes" do
    @organization.update!(status: "suspended")

    assert_raises(ActiveRecord::RecordInvalid) do
      @program.apply!(student: users(:student), statement: "I want to learn.")
    end
    assert_empty @program.applications
  end
end
