require "test_helper"

class Recruitment::SavedJobTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Saved Job Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(
      creator: users(:two), title: "Saved Role", summary: "Summary", description: "Description",
      category: "Product", department: "Innovation", team: "Academy", seniority: "Junior",
      employment_type: "full_time", location: "Bangkok", remote_policy: "hybrid"
    )
    @job.transition_to!("review")
    @job.transition_to!("published")
  end

  test "a student can save a discoverable job once" do
    saved = users(:one).saved_jobs.create!(job_post: @job)
    duplicate = users(:one).saved_jobs.build(job_post: @job)

    assert_equal @job, saved.job_post
    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:user_id], :any?
  end

  test "staff and non-discoverable jobs cannot be saved" do
    staff_save = Recruitment::SavedJob.new(user: users(:instructor), job_post: @job)
    assert_not staff_save.valid?
    assert_predicate staff_save.errors[:user], :any?

    @job.transition_to!("paused")
    hidden_save = Recruitment::SavedJob.new(user: users(:one), job_post: @job)
    assert_not hidden_save.valid?
    assert_predicate hidden_save.errors[:job_post], :any?
  end
end
