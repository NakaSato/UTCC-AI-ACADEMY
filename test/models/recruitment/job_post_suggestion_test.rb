require "test_helper"

class Recruitment::JobPostSuggestionTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Suggestion Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job_post = @organization.job_posts.create!(
      creator: users(:two), title: "AI Product Analyst", summary: "Existing summary",
      description: "Existing description", category: "Product", department: "Innovation",
      team: "Academy", seniority: "Mid-level", employment_type: "full_time",
      location: "Bangkok", remote_policy: "hybrid", hiring_reason: "Grow the product team",
      positions_count: 2
    )
  end

  test "generates labelled suggestions from an allow-listed employer context" do
    suggestions = Recruitment::JobSuggestionGenerator.call(job_post: @job_post, requested_by: users(:two))

    assert_equal Recruitment::JobPostSuggestion::KINDS.sort, suggestions.map(&:kind).sort
    assert suggestions.all?(&:actionable?)
    assert suggestions.all? { |suggestion| suggestion.provider == "rules_preview" }
    assert suggestions.all? { |suggestion| suggestion.source_context.keys.sort == Recruitment::JobSuggestionGenerator::CONTEXT_FIELDS.sort }
    assert_not suggestions.first.source_context.key?("candidate_profile")
  end

  test "rejects invalid suggestion provenance and unauthorized requesters" do
    invalid = @job_post.suggestions.new(
      requested_by: users(:two), kind: "summary", content: "Text", provider: "unknown",
      source_label: "Source", uncertainty: "Uncertain"
    )
    assert_not invalid.valid?
    assert_predicate invalid.errors[:provider], :any?

    mentor = @organization.memberships.create!(user: users(:student), role: "mentor")
    unauthorized = @job_post.suggestions.new(
      requested_by: mentor.user, kind: "summary", content: "Text", provider: "rules_preview",
      source_label: "Source", uncertainty: "Uncertain"
    )
    assert_not unauthorized.valid?
    assert_predicate unauthorized.errors[:requested_by], :any?
  end

  test "editing and accepting a summary updates only the editable job" do
    suggestion = Recruitment::JobSuggestionGenerator.call(job_post: @job_post, requested_by: users(:two), only: "summary").first

    suggestion.edit!("Human-reviewed summary", reviewer: users(:two))
    suggestion.accept!(reviewer: users(:one))

    assert_equal "Human-reviewed summary", @job_post.reload.summary
    assert_equal "accepted", suggestion.reload.status
    assert_predicate @job_post.reload, :draft?
  end

  test "accepted summary suggestions cannot overwrite a published job" do
    @job_post.transition_to!("review")
    @job_post.transition_to!("published")
    suggestion = @job_post.suggestions.create!(
      requested_by: users(:two), kind: "summary", content: "Replacement",
      provider: "rules_preview", source_label: "Source", uncertainty: "Uncertain"
    )

    assert_raises(ActiveRecord::RecordInvalid) { suggestion.accept!(reviewer: users(:one)) }
    assert_equal "Existing summary", @job_post.reload.summary
    assert_predicate suggestion.reload, :actionable?
  end
end
