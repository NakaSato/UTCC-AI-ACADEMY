require "test_helper"

class Recruitment::JobPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Controller Job Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:student), role: "mentor")
    sign_in_as users(:two)
  end

  def job_params(title: "AI Product Analyst")
    {
      recruitment_job_post: {
        title:,
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
        currency: "THB"
      }
    }
  end

  test "recruiter creates and updates an organization-scoped draft" do
    assert_difference [ "Recruitment::JobPost.count", "AuditEvent.count" ], 1 do
      post recruitment_organization_job_posts_path(@organization), params: job_params
    end

    job = @organization.job_posts.order(:id).last
    assert_redirected_to recruitment_organization_job_post_path(@organization, job)
    assert_predicate job, :draft?
    assert_equal users(:two), job.creator

    patch recruitment_organization_job_post_path(@organization, job), params: {
      recruitment_job_post: job_params[:recruitment_job_post].merge(
        title: "Senior AI Product Analyst", lock_version: job.lock_version
      )
    }

    assert_redirected_to recruitment_organization_job_post_path(@organization, job)
    assert_equal "Senior AI Product Analyst", job.reload.title
  end

  test "mentor cannot create a job and a non-member cannot read organization jobs" do
    sign_out
    sign_in_as users(:student)
    assert_no_difference "Recruitment::JobPost.count" do
      post recruitment_organization_job_posts_path(@organization), params: job_params
    end
    assert_response :not_found

    sign_out
    sign_in_as users(:instructor)
    get recruitment_organization_job_posts_path(@organization)
    assert_response :not_found
  end

  test "recruiter submits for review and owner publishes" do
    post recruitment_organization_job_posts_path(@organization), params: job_params
    job = @organization.job_posts.order(:id).last

    assert_difference "AuditEvent.count", 1 do
      post submit_recruitment_organization_job_post_path(@organization, job)
    end
    assert_predicate job.reload, :review?

    post publish_recruitment_organization_job_post_path(@organization, job)
    assert_response :not_found
    assert_predicate job.reload, :review?

    sign_out
    sign_in_as users(:one)
    assert_difference "AuditEvent.count", 1 do
      post publish_recruitment_organization_job_post_path(@organization, job)
    end
    assert_redirected_to recruitment_organization_job_post_path(@organization, job)
    assert_predicate job.reload, :published?
  end

  test "published jobs are visible to candidates but drafts and expired jobs are hidden" do
    post recruitment_organization_job_posts_path(@organization), params: job_params
    draft = @organization.job_posts.order(:id).last
    post submit_recruitment_organization_job_post_path(@organization, draft)
    sign_out
    sign_in_as users(:one)
    post publish_recruitment_organization_job_post_path(@organization, draft)

    expired = @organization.job_posts.create!(
      creator: users(:two), title: "Expired", summary: "Old", description: "Old details",
      category: "Product", department: "Innovation", team: "Academy", seniority: "Junior",
      employment_type: "full_time", location: "Bangkok", remote_policy: "onsite", closes_on: 1.day.ago
    )
    expired.transition_to!("review")
    expired.transition_to!("published")

    get recruitment_jobs_path
    assert_response :success
    assert_select "a[href=?]", recruitment_job_path(draft)
    assert_select "a[href=?]", recruitment_job_path(expired), count: 0

    get recruitment_job_path(draft)
    assert_response :success
    get recruitment_job_path(expired)
    assert_response :not_found
  end

  test "owner can pause, close, archive, and delete drafts" do
    post recruitment_organization_job_posts_path(@organization), params: job_params
    job = @organization.job_posts.order(:id).last
    post submit_recruitment_organization_job_post_path(@organization, job)

    sign_out
    sign_in_as users(:one)
    post publish_recruitment_organization_job_post_path(@organization, job)
    post pause_recruitment_organization_job_post_path(@organization, job)
    assert_predicate job.reload, :paused?
    post close_recruitment_organization_job_post_path(@organization, job)
    post archive_recruitment_organization_job_post_path(@organization, job)
    assert_predicate job.reload, :archived?

    draft = @organization.job_posts.create!(creator: users(:one))
    assert_difference "Recruitment::JobPost.count", -1 do
      delete recruitment_organization_job_post_path(@organization, draft)
    end
  end
end
