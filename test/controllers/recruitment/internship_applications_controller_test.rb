require "test_helper"

class Recruitment::InternshipApplicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Application Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:one), mentor: users(:instructor), name: "Open Internship", department: "AI",
      description: "A published program.", duration_weeks: 6, max_students: 1, required_skills: "Learning",
      learning_outcomes: "Deliver a project.", working_days: "Weekdays", remote_policy: "hybrid", paid: false,
      certificate_policy: "Completion review", equipment_provided: "Laptop"
    )
    @program.transition_to!("review")
    @program.transition_to!("published")
    sign_in_as users(:student)
  end

  test "a student applies once and can withdraw their own application" do
    assert_difference "Recruitment::InternshipApplication.count", 1 do
      post recruitment_apply_internship_path(@program), params: {
        recruitment_internship_application: { statement: "I want practical experience." }
      }
    end

    application = @program.applications.sole
    assert_redirected_to recruitment_internship_path(@program)
    assert_predicate application, :pending?

    post recruitment_withdraw_internship_application_path(application)
    assert_predicate application.reload, :withdrawn?
  end

  test "an owner accepts an application but a full program rejects another" do
    post recruitment_apply_internship_path(@program), params: { recruitment_internship_application: { statement: "First" } }
    first = @program.applications.sole

    sign_out
    sign_in_as users(:one)
    post accept_recruitment_organization_internship_program_application_path(@organization, @program, first)
    assert_predicate first.reload, :accepted?

    second_student = User.create!(name: "Second applicant", student_id: "9999999999997", password: "Student99")
    sign_out
    sign_in_as second_student
    post recruitment_apply_internship_path(@program), params: { recruitment_internship_application: { statement: "Second" } }

    assert_equal 1, @program.applications.where(status: "accepted").count
    assert_equal 1, @program.applications.count
  end

  test "a mentor cannot decide applications from another organization" do
    outsider = Organization.create!(name: "Other Internship Org", creator: users(:admin))
    outsider.memberships.create!(user: users(:instructor), role: "mentor")
    sign_out
    sign_in_as users(:instructor)

    get recruitment_organization_internship_program_applications_path(outsider, @program)

    assert_response :not_found
  end
end
