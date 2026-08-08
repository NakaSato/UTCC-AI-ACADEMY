require "test_helper"

class Recruitment::InternshipEvaluationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Internship Evaluation Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @program = @organization.internship_programs.create!(
      creator: users(:one), mentor: users(:instructor), name: "Evaluation Internship", department: "AI",
      description: "Learn evaluation.", duration_weeks: 4, max_students: 1, required_skills: "Care",
      learning_outcomes: "Give evidence-based feedback.", working_days: "Fridays", remote_policy: "onsite",
      paid: false, certificate_policy: "Reviewed completion", equipment_provided: "Workspace"
    )
    @program.transition_to!("review")
    @program.transition_to!("published")
    @application = @program.applications.create!(student: users(:student), statement: "I want to learn.")
    @application.accept!(reviewer: users(:one))
  end

  test "a mentor can submit one complete evaluation" do
    evaluation = @application.build_evaluation(
      evaluator: users(:instructor), status: "submitted", rating: 5, learning_outcomes_met: true,
      feedback: "Strong evidence.", next_steps: "Keep building."
    )

    evaluation.submit!

    assert_predicate evaluation.reload, :submitted?
    assert evaluation.submitted_at
  end

  test "a submitted evaluation requires a rating and feedback" do
    evaluation = @application.build_evaluation(
      evaluator: users(:instructor), status: "submitted", learning_outcomes_met: true,
      feedback: "", next_steps: ""
    )

    assert_not evaluation.valid?
    assert_predicate evaluation.errors[:rating], :any?
    assert_predicate evaluation.errors[:feedback], :any?
  end

  test "a mentor who is not assigned to the program cannot evaluate" do
    other_mentor = User.create!(name: "Other mentor", student_id: "9999999999998", role: "instructor", password: "Mentor99")
    @organization.memberships.create!(user: other_mentor, role: "mentor")
    evaluation = @application.build_evaluation(
      evaluator: other_mentor, status: "submitted", rating: 3, learning_outcomes_met: true,
      feedback: "Feedback", next_steps: "Next"
    )

    assert_not evaluation.valid?
    assert_predicate evaluation.errors[:evaluator], :any?
  end

  test "a non-member cannot evaluate an organization's application" do
    evaluation = @application.build_evaluation(
      evaluator: users(:two), status: "submitted", rating: 3, learning_outcomes_met: true,
      feedback: "Feedback", next_steps: "Next"
    )

    assert_not evaluation.valid?
    assert_predicate evaluation.errors[:evaluator], :any?
  end

  test "a suspended organization rejects evaluation writes" do
    @organization.update!(status: "suspended")
    assert_not @organization.active?
    evaluation = @application.build_evaluation(
      evaluator: users(:instructor), status: "submitted", rating: 3, learning_outcomes_met: true,
      feedback: "Feedback", next_steps: "Next"
    )

    assert_raises(ActiveRecord::RecordInvalid) { evaluation.submit! }
    assert_nil @application.reload.evaluation
  end
end
