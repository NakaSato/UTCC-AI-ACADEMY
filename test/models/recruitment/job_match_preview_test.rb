require "test_helper"

class Recruitment::JobMatchPreviewTest < ActiveSupport::TestCase
  setup do
    organization = Organization.create!(name: "Match Org", creator: users(:admin))
    organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = organization.job_posts.create!(
      creator: users(:two), title: "Ruby Analyst", summary: "Use Ruby in Bangkok.", description: "Build tools.",
      category: "Product", department: "Innovation", team: "Academy", seniority: "Mid-level",
      employment_type: "full_time", location: "Bangkok", remote_policy: "hybrid",
      salary_min: 30_000, salary_max: 50_000, currency: "THB"
    )
    @job.transition_to!("review")
    @job.transition_to!("published")
  end

  test "preview exposes factor evidence and uncertainty without an aggregate score" do
    profile = users(:one).create_candidate_profile!(preferred_location: "Bangkok", salary_expectation_min: 35_000,
                                                    salary_expectation_max: 45_000, salary_currency: "THB")
    profile.facts.create!(kind: "skill", title: "Ruby")
    profile.facts.create!(kind: "experience", title: "Product analyst")

    preview = Recruitment::JobMatchPreview.call(user: users(:one), job_post: @job)

    assert_equal Recruitment::JobMatchPreview::FACTOR_KEYS, preview.factors.map(&:key)
    assert_equal "match", preview.factors.find { |factor| factor.key == "skill_fit" }.state
    assert_equal "match", preview.factors.find { |factor| factor.key == "salary_fit" }.state
    assert preview.factors.all? { |factor| factor.evidence.present? && factor.uncertainty.present? }
    assert_not preview.to_h.key?(:score)
    assert_includes preview.uncertainty, "not a hiring score"
  end

  test "missing evidence is unknown rather than a rejection" do
    users(:one).create_candidate_profile!

    preview = Recruitment::JobMatchPreview.call(user: users(:one), job_post: @job)

    assert_equal "unknown", preview.factors.find { |factor| factor.key == "skill_fit" }.state
    assert_equal "unknown", preview.factors.find { |factor| factor.key == "salary_fit" }.state
  end

  test "staff and hidden jobs have no candidate match preview" do
    assert_nil Recruitment::JobMatchPreview.call(user: users(:instructor), job_post: @job)
    @job.transition_to!("paused")
    assert_nil Recruitment::JobMatchPreview.call(user: users(:one), job_post: @job)
  end
end
