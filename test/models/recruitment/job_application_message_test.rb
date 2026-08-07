require "test_helper"

class Recruitment::JobApplicationMessageTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Application Message Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @job = @organization.job_posts.create!(creator: users(:two), title: "Product Analyst", summary: "Learn from evidence.",
                                           description: "Work with the product team.", category: "Product",
                                           department: "Academy", team: "Platform", seniority: "Junior",
                                           location: "Bangkok")
    @job.transition_to!("review")
    @job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    @outsider = User.create!(name: "Outside Student", student_id: "2011071730888", password: "OutsidePass9")
    @application = Recruitment::JobApplication.submit!(job_post: @job, candidate: users(:student), statement: "Ready")
  end

  test "candidate and authorized hiring members can send normalized messages" do
    message = @application.messages.create!(sender: users(:student), body: "  Hello hiring team.  ")

    assert_equal "Hello hiring team.", message.body
    assert_equal users(:student), message.sender
    assert_predicate message.sent_at, :present?

    reviewer_message = @application.messages.create!(sender: users(:two), body: "Thanks for applying.")

    assert_equal [ users(:student), users(:two) ], @application.messages.order(:id).map(&:sender)
    assert_equal "Thanks for applying.", reviewer_message.body
  end

  test "a mentor or unrelated user cannot send an application message" do
    [ users(:instructor), @outsider ].each do |sender|
      message = @application.messages.build(sender:, body: "Not allowed")

      assert_not message.valid?
      assert_predicate message.errors[:sender], :any?
    end
  end

  test "messages require nonblank plain text within the boundary" do
    assert_not @application.messages.build(sender: users(:student), body: " \n ").valid?
    assert_not @application.messages.build(sender: users(:student), body: "x" * 4_001).valid?
  end

  test "creating a message does not change the application stage" do
    assert_no_changes -> { @application.reload.status } do
      @application.messages.create!(sender: users(:student), body: "Still waiting for review.")
    end
  end
end
