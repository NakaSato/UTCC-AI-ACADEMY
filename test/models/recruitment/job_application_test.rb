require "test_helper"

class Recruitment::JobApplicationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Application Model Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(creator: users(:two), title: "Product Analyst", summary: "Learn from evidence.",
                                           description: "Work with the product team.", category: "Product",
                                           department: "Academy", team: "Platform", seniority: "Junior",
                                           location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
  end

  test "submission captures consented profile evidence and an initial event" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "I can help.")

    assert_predicate application, :submitted?
    assert_equal users(:student), application.candidate
    assert_equal "I can help.", application.statement
    assert_equal 1, application.events.count
    assert_equal "submitted", application.events.sole.to_status
    assert_equal true, application.application_snapshot.dig("profile", "application_data_reuse_consent")
  end

  test "submission requires explicit application-data reuse consent" do
    profile = users(:student).candidate_profile
    profile.update!(application_data_reuse_consent: false)

    application = Recruitment::JobApplication.new(job_post: @job, candidate: users(:student), statement: "No")

    assert_not application.valid?
    assert_predicate application.errors[:base], :any?
    assert_no_difference "Recruitment::JobApplication.count" do
      assert_raises ActiveRecord::RecordInvalid do
        Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "No")
      end
    end
  end

  test "reviewer transitions are explicit, evented, and reversible where allowed" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")

    application.transition_to!("screening", actor: users(:two), note: "Initial review")
    application.transition_to!("submitted", actor: users(:two), note: "Need more context")

    assert_predicate application.reload, :submitted?
    assert_equal %w[ submitted screening submitted ], application.events.order(:id).pluck(:to_status)
    assert_equal "Need more context", application.events.order(:id).last.note
  end

  test "non-reviewers cannot transition and terminal applications cannot move" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")

    assert_raises ActiveRecord::RecordInvalid do
      application.transition_to!("screening", actor: users(:student))
    end
    application.transition_to!("rejected", actor: users(:two))

    assert_raises ActiveRecord::RecordInvalid do
      application.transition_to!("screening", actor: users(:two))
    end
  end

  test "direct status updates cannot bypass the transition and event boundary" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")

    assert_not application.update(status: "screening")
    assert_predicate application.errors[:status], :any?
    assert_predicate application.reload, :submitted?
  end

  test "a stale reviewer version cannot overwrite a newer decision" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")
    stale_version = application.lock_version
    application.transition_to!("screening", actor: users(:two))

    assert_raises ActiveRecord::StaleObjectError do
      application.transition_to!("rejected", actor: users(:two), lock_version: stale_version)
    end
    assert_predicate application.reload, :screening?
  end

  test "only the candidate can withdraw from an open stage" do
    application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")

    application.withdraw!(actor: users(:student))

    assert_predicate application.reload, :withdrawn?
    assert_equal "withdrawn", application.events.order(:id).last.to_status
  end
end
