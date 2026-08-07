require "test_helper"

class Recruitment::InternshipProgramSuggestionTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Internship Suggestion Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:two), mentor: users(:instructor), name: "AI Learning Program", department: "Innovation",
      description: "Existing description", duration_weeks: 8, max_students: 2, required_skills: "Teamwork",
      learning_outcomes: "Build a reviewed project.", working_days: "Weekdays", remote_policy: "hybrid",
      paid: false, certificate_policy: "Review required", equipment_provided: "Laptop"
    )
  end

  test "generates labelled suggestions from an allow-listed program context" do
    suggestions = Recruitment::InternshipSuggestionGenerator.call(program: @program, requested_by: users(:two))

    assert_equal Recruitment::InternshipProgramSuggestion::KINDS.sort, suggestions.map(&:kind).sort
    assert suggestions.all?(&:actionable?)
    assert suggestions.all? { |suggestion| suggestion.provider == "rules_preview" }
    assert suggestions.all? { |suggestion| suggestion.source_context.keys.sort == Recruitment::InternshipSuggestionGenerator::CONTEXT_FIELDS.sort }
    assert_not suggestions.first.source_context.key?("student")
  end

  test "editing and accepting a description updates only an editable program" do
    suggestion = Recruitment::InternshipSuggestionGenerator.call(program: @program, requested_by: users(:two), only: "description").first

    suggestion.edit!("Human-reviewed program description", reviewer: users(:two))
    suggestion.accept!(reviewer: users(:one))

    assert_equal "Human-reviewed program description", @program.reload.description
    assert_equal "accepted", suggestion.reload.status
    assert_predicate @program, :draft?
  end

  test "accepted descriptions cannot overwrite a published program" do
    @program.transition_to!("review")
    @program.transition_to!("published")
    suggestion = @program.suggestions.create!(
      requested_by: users(:two), kind: "description", content: "Replacement", provider: "rules_preview",
      source_label: "Source", uncertainty: "Uncertain"
    )

    assert_raises(ActiveRecord::RecordInvalid) { suggestion.accept!(reviewer: users(:one)) }
    assert_equal "Existing description", @program.reload.description
    assert_predicate suggestion.reload, :actionable?
  end
end
