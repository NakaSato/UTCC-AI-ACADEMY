require "test_helper"

class Recruitment::JobSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Suggestion Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    @job_post = @organization.job_posts.create!(
      creator: users(:two), title: "AI Product Analyst", summary: "Existing summary",
      description: "Existing description", category: "Product", department: "Innovation",
      team: "Academy", seniority: "Mid-level", employment_type: "full_time",
      location: "Bangkok", remote_policy: "hybrid", hiring_reason: "Grow the product team",
      positions_count: 2
    )
    sign_in_as users(:two)
  end

  test "recruiter generates, edits, and accepts a suggestion without publishing" do
    assert_difference "Recruitment::JobPostSuggestion.count", 5 do
      assert_difference "AuditEvent.count", 1 do
        post suggestions_company_job_post_path(@organization, @job_post)
      end
    end

    summary = @job_post.suggestions.find_by!(kind: "summary")
    assert_redirected_to company_job_post_path(@organization, @job_post)
    assert_select "body", /rules_preview/ if response.body.present?

    patch company_job_post_suggestion_path(@organization, @job_post, summary), params: {
      recruitment_job_post_suggestion: { content: "Human-reviewed summary" }
    }
    assert_equal "edited", summary.reload.status

    post accept_company_job_post_suggestion_path(@organization, @job_post, summary)
    assert_redirected_to company_job_post_path(@organization, @job_post)
    assert_equal "Human-reviewed summary", @job_post.reload.summary
    assert_predicate @job_post, :draft?
  end

  test "mentor and non-member cannot generate or review suggestions" do
    sign_out
    sign_in_as users(:student)
    assert_no_difference "Recruitment::JobPostSuggestion.count" do
      post suggestions_company_job_post_path(@organization, @job_post)
    end
    assert_response :not_found

    sign_out
    sign_in_as users(:instructor)
    get company_job_post_path(@organization, @job_post)
    assert_response :not_found
  end

  test "rejection and regeneration preserve the old decision and create a new pending suggestion" do
    post suggestions_company_job_post_path(@organization, @job_post)
    original = @job_post.suggestions.find_by!(kind: "requirements")

    post reject_company_job_post_suggestion_path(@organization, @job_post, original)
    assert_equal "rejected", original.reload.status

    assert_difference "Recruitment::JobPostSuggestion.count", 1 do
      post regenerate_company_job_post_suggestion_path(@organization, @job_post, original)
    end

    assert_predicate @job_post.suggestions.find_by!(kind: "requirements", status: "pending"), :actionable?
    assert_equal "rejected", original.reload.status
  end

  test "a published job cannot accept a summary suggestion" do
    @job_post.transition_to!("review")
    @job_post.transition_to!("published")
    suggestion = @job_post.suggestions.create!(
      requested_by: users(:two), kind: "summary", content: "Replacement",
      provider: "rules_preview", source_label: "Source", uncertainty: "Uncertain"
    )

    sign_out
    sign_in_as users(:one)
    post accept_company_job_post_suggestion_path(@organization, @job_post, suggestion)

    assert_redirected_to company_job_post_path(@organization, @job_post)
    assert_equal "Existing summary", @job_post.reload.summary
    assert_predicate suggestion.reload, :actionable?
  end
end
