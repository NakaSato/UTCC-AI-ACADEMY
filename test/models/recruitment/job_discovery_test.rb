require "test_helper"

class Recruitment::JobDiscoveryTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Discovery Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @ruby_job = create_published_job(title: "Ruby Product Analyst", summary: "Use Ruby to improve learning tools.")
    @python_job = create_published_job(title: "Python Data Analyst", summary: "Build data reports for the academy.")
  end

  test "search filters only currently visible published jobs" do
    results = Recruitment::JobDiscovery.search(query: "ruby", remote_policy: "hybrid")

    assert_equal [ @ruby_job.id ], results.map(&:id)
    assert_empty Recruitment::JobDiscovery.search(query: "ruby", remote_policy: "remote")
  end

  test "search bounds and escapes free-text filters" do
    assert_empty Recruitment::JobDiscovery.search(location: "%")
    assert_empty Recruitment::JobDiscovery.search(query: "ruby" + ("x" * 160))
  end

  test "recommendations explain profile evidence without a hiring score" do
    profile = users(:one).create_candidate_profile!
    profile.facts.create!(kind: "skill", title: "Ruby", detail: "Rails projects")

    recommendations = Recruitment::JobDiscovery.recommend(user: users(:one))

    assert_equal [ @ruby_job ], recommendations.map(&:job_post)
    assert_includes recommendations.first.reasons.first, "Ruby"
    assert_includes recommendations.first.uncertainty, "Advisory"
    assert_not recommendations.first.to_h.key?(:score)
  end

  test "saved and dismissed jobs are excluded until restored" do
    users(:one).create_candidate_profile!.facts.create!(kind: "skill", title: "Ruby")
    users(:one).saved_jobs.create!(job_post: @ruby_job)
    users(:one).job_discovery_dismissals.create!(job_post: @python_job)

    assert_empty Recruitment::JobDiscovery.recommend(user: users(:one))

    users(:one).saved_jobs.find_by!(job_post: @ruby_job).destroy!
    users(:one).job_discovery_dismissals.find_by!(job_post: @python_job).destroy!

    assert_equal [ @ruby_job ], Recruitment::JobDiscovery.recommend(user: users(:one)).map(&:job_post)
  end

  test "alerts are consented and frequency limited" do
    preference = users(:one).create_job_discovery_preference!(alert_consent: true, alerts_enabled: true,
                                                              alert_frequency: "daily")
    assert_predicate preference, :alerts_due?
    preference.update!(last_alert_sent_at: Time.current)
    assert_not preference.alerts_due?
    preference.update!(last_alert_sent_at: 2.days.ago)
    assert_predicate preference, :alerts_due?
  end

  test "revoking alert consent disables alerts and clears its timestamp" do
    preference = users(:one).create_job_discovery_preference!(alert_consent: true, alerts_enabled: true)

    preference.update!(alert_consent: false)

    assert_not preference.alert_consent?
    assert_not preference.alerts_enabled?
    assert_nil preference.alert_consent_given_at
  end

  private
    def create_published_job(title:, summary:)
      job = @organization.job_posts.create!(
        creator: users(:two), title:, summary:, description: "Deliver measurable results for the team.",
        category: "Data", department: "Innovation", team: "Academy", seniority: "Mid-level",
        employment_type: "full_time", location: "Bangkok", remote_policy: "hybrid"
      )
      job.transition_to!("review")
      job.transition_to!("published")
      job
    end
end
