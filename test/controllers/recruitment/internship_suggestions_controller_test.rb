require "test_helper"

class Recruitment::InternshipSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Internship Suggestion Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:two), mentor: users(:student), name: "Suggestion Program", department: "AI",
      description: "Existing description", duration_weeks: 8, max_students: 2, required_skills: "Learning",
      learning_outcomes: "Build a project.", working_days: "Weekdays", remote_policy: "remote", paid: false,
      certificate_policy: "Review", equipment_provided: "Laptop"
    )
    sign_in_as users(:two)
  end

  test "a recruiter generates, edits, and accepts a program suggestion" do
    assert_difference "Recruitment::InternshipProgramSuggestion.count", 5 do
      assert_difference "AuditEvent.count", 1 do
        post suggestions_recruitment_organization_internship_program_path(@organization, @program)
      end
    end

    suggestion = @program.suggestions.find_by!(kind: "description")
    patch recruitment_organization_internship_program_suggestion_path(@organization, @program, suggestion), params: {
      recruitment_internship_program_suggestion: { content: "Human-reviewed description" }
    }
    assert_equal "edited", suggestion.reload.status

    post accept_recruitment_organization_internship_program_suggestion_path(@organization, @program, suggestion)
    assert_equal "Human-reviewed description", @program.reload.description
    assert_predicate @program, :draft?
  end

  test "rejection and regeneration preserve the old decision" do
    post suggestions_recruitment_organization_internship_program_path(@organization, @program)
    suggestion = @program.suggestions.find_by!(kind: "learning_roadmap")

    post reject_recruitment_organization_internship_program_suggestion_path(@organization, @program, suggestion)
    assert_equal "rejected", suggestion.reload.status

    assert_difference "Recruitment::InternshipProgramSuggestion.count", 1 do
      post regenerate_recruitment_organization_internship_program_suggestion_path(@organization, @program, suggestion)
    end

    assert_predicate @program.suggestions.find_by!(kind: "learning_roadmap", status: "pending"), :actionable?
    assert_equal "rejected", suggestion.reload.status
  end

  test "a student cannot generate or review program suggestions" do
    sign_out
    sign_in_as users(:student)

    post suggestions_recruitment_organization_internship_program_path(@organization, @program)

    assert_response :not_found
  end
end
