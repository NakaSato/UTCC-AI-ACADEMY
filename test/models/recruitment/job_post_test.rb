require "test_helper"

class Recruitment::JobPostTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Job Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
  end

  def job_attributes
    {
      title: "AI Product Analyst",
      summary: "Turn customer evidence into product decisions.",
      description: "Work with product and engineering teams to improve learning tools.",
      category: "Product",
      department: "Innovation",
      team: "Academy Platform",
      seniority: "Mid-level",
      employment_type: "full_time",
      location: "Bangkok",
      remote_policy: "hybrid",
      salary_min: 40_000,
      salary_max: 70_000,
      currency: "thb"
    }
  end

  test "creates a draft with structured defaults" do
    job = @organization.job_posts.create!(job_attributes.merge(creator: users(:two)))

    assert_predicate job, :draft?
    assert_equal "THB", job.currency
    assert_equal "full_time", job.employment_type
    assert_equal "hybrid", job.remote_policy
    assert_predicate job, :ready_for_publication?
  end

  test "rejects invalid salary ranges and unauthorized creators" do
    invalid_salary = @organization.job_posts.new(job_attributes.merge(creator: users(:two), salary_min: 80_000, salary_max: 70_000))
    assert_not invalid_salary.valid?
    assert_predicate invalid_salary.errors[:salary_max], :any?

    mentor_job = @organization.job_posts.new(job_attributes.merge(creator: users(:student)))
    assert_not mentor_job.valid?
    assert_predicate mentor_job.errors[:creator], :any?

    stranger_job = @organization.job_posts.new(job_attributes.merge(creator: users(:instructor)))
    assert_not stranger_job.valid?
    assert_predicate stranger_job.errors[:creator], :any?
  end

  test "requires a complete review state before publication" do
    incomplete = @organization.job_posts.create!(creator: users(:two), title: "Incomplete")
    assert_raises(ActiveRecord::RecordInvalid) { incomplete.transition_to!("review") }

    job = @organization.job_posts.create!(job_attributes.merge(creator: users(:two)))
    assert_raises(ActiveRecord::RecordInvalid) { job.transition_to!("published") }
    job.transition_to!("review")
    job.transition_to!("published")

    assert_predicate job.reload, :published?
    assert job.published_at.present?
  end

  test "illegal transitions fail without changing the job" do
    job = @organization.job_posts.create!(job_attributes.merge(creator: users(:two)))

    assert_raises(ActiveRecord::RecordInvalid) { job.transition_to!("closed") }
    assert_predicate job.reload, :draft?

    job.transition_to!("review")
    job.transition_to!("published")
    job.transition_to!("paused")
    job.transition_to!("published")
    job.transition_to!("closed")
    job.transition_to!("archived")

    assert_predicate job.reload, :archived?
    assert job.closed_at.present?
    assert job.archived_at.present?
  end

  test "candidate visibility excludes non-published, inactive, and expired jobs" do
    visible = @organization.job_posts.create!(job_attributes.merge(creator: users(:two)))
    visible.transition_to!("review")
    visible.transition_to!("published")

    paused = @organization.job_posts.create!(job_attributes.merge(creator: users(:two), title: "Paused"))
    paused.transition_to!("review")
    paused.transition_to!("published")
    paused.transition_to!("paused")

    expired = @organization.job_posts.create!(job_attributes.merge(creator: users(:two), title: "Expired", closes_on: 1.day.ago))
    expired.transition_to!("review")
    expired.transition_to!("published")

    assert_equal [ visible.id ], Recruitment::JobPost.published_for_candidates.pluck(:id)

    @organization.update!(status: "suspended")
    assert_empty Recruitment::JobPost.published_for_candidates
  end

  test "a company reviewer authors job posts but does not hold approval authority" do
    @organization.memberships.create!(user: users(:instructor), role: "company_reviewer")

    job = @organization.job_posts.create!(job_attributes.merge(creator: users(:instructor)))

    assert_predicate job, :draft?
    assert_includes Recruitment::JobPost::AUTHOR_ROLES, "company_reviewer"
    assert_not_includes Recruitment::JobPost::APPROVER_ROLES, "company_reviewer",
      "publication approval stays with the owner and hiring manager"
    assert_includes Recruitment::JobApplication::REVIEWER_ROLES, "company_reviewer"
    assert_includes Recruitment::OrganizationReporting::REPORTER_ROLES, "company_reviewer"
  end

  test "only drafts can be deleted" do
    draft = @organization.job_posts.create!(job_attributes.merge(creator: users(:two)))
    assert_difference "Recruitment::JobPost.count", -1 do
      draft.destroy!
    end

    published = @organization.job_posts.create!(job_attributes.merge(creator: users(:two), title: "Published"))
    published.transition_to!("review")
    published.transition_to!("published")
    assert_not published.destroy
    assert_predicate published.reload, :published?
  end
end
