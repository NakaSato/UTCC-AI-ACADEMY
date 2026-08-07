require "test_helper"

class Recruitment::InternshipEvaluationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Evaluation Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:one), mentor: users(:instructor), name: "Evaluated Internship", department: "AI",
      description: "A program with evaluation.", duration_weeks: 6, max_students: 1, required_skills: "Learning",
      learning_outcomes: "Deliver a project.", working_days: "Weekdays", remote_policy: "onsite", paid: false,
      certificate_policy: "Review required", equipment_provided: "Workspace"
    )
    @program.transition_to!("review")
    @program.transition_to!("published")
    @application = @program.applications.create!(student: users(:student), statement: "I want to learn.")
    @application.accept!(reviewer: users(:one))
    sign_in_as users(:instructor)
  end

  test "the assigned mentor submits a structured evaluation" do
    assert_difference [ "Recruitment::InternshipEvaluation.count", "AuditEvent.count" ], 1 do
      post recruitment_organization_internship_program_application_evaluation_path(@organization, @program, @application), params: {
        recruitment_internship_evaluation: {
          rating: 4, learning_outcomes_met: "true", feedback: "Good evidence.", next_steps: "Keep practicing."
        }
      }
    end

    evaluation = @application.reload.evaluation
    assert_redirected_to recruitment_organization_internship_program_path(@organization, @program)
    assert_predicate evaluation, :submitted?
  end

  test "a non-assigned mentor cannot submit an evaluation" do
    other_mentor = User.create!(name: "Other evaluator", student_id: "9999999999996", role: "instructor", password: "Mentor99")
    @organization.memberships.create!(user: other_mentor, role: "mentor")
    sign_out
    sign_in_as other_mentor

    post recruitment_organization_internship_program_application_evaluation_path(@organization, @program, @application), params: {
      recruitment_internship_evaluation: {
        rating: 4, learning_outcomes_met: "true", feedback: "No.", next_steps: "No."
      }
    }

    assert_response :not_found
    assert_nil @application.reload.evaluation
  end
end
