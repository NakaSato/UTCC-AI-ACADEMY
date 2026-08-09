require "application_system_test_case"

# One sign-in per test, matching every other system test here.
class InternshipRequestWalkTest < ApplicationSystemTestCase
  setup do
    @student = users(:student)
    @decider = users(:one)
    @organization = Organization.create!(name: "Walkthrough Logistics", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: @decider, role: "owner")
  end

  test "a student drafts a request to a company that advertised nothing and submits it" do
    sign_in_through_the_form(@student)

    visit internship_requests_path
    assert_text th("internship_requests.positionless_notice")

    click_link th("internship_requests.new")
    select @organization.name, from: "internship_request[organization_id]"
    fill_in "internship_request_motivation", with: "สนใจงานคลังสินค้าและการวางเส้นทางของบริษัท"
    fill_in "internship_request_learning_goals", with: "อยากเรียนรู้การวิเคราะห์ต้นทุนขนส่ง"
    click_button th("internship_requests.save")

    assert_text th("flash.internship_request_created")
    assert_text th("internship_requests.status.draft")
    assert_text "สนใจงานคลังสินค้าและการวางเส้นทางของบริษัท"

    click_button th("internship_requests.submit_request")

    assert_text th("flash.internship_request_submitted")
    assert_text th("internship_requests.status.submitted")
    # A submitted request is out of the student's hands.
    assert_no_selector "a", text: th("internship_requests.edit")
  end

  test "a company decider reviews the queue and records a decision with a reason" do
    internship_request = @organization.internship_requests.create!(
      student: @student,
      motivation: "สนใจงานคลังสินค้าและการวางเส้นทางของบริษัท",
      learning_goals: "อยากเรียนรู้การวิเคราะห์ต้นทุนขนส่ง"
    )
    internship_request.submit!(actor: @student)

    sign_in_through_the_form(@decider)

    visit company_internship_requests_path(@organization)
    assert_text @student.name
    assert_text "สนใจงานคลังสินค้าและการวางเส้นทางของบริษัท"

    click_button th("internship_requests.start_review")
    assert_text th("flash.internship_request_review_started")
    assert_text th("internship_requests.status.under_review")

    fill_in "decision_reason", with: "รอบนี้เต็มแล้ว แต่ยินดีพิจารณาเทอมหน้า"
    click_button th("internship_requests.reject")

    assert_text th("flash.internship_request_rejected")
    assert_text th("internship_requests.status.rejected")
    assert_text "รอบนี้เต็มแล้ว แต่ยินดีพิจารณาเทอมหน้า"
  end

  private
    def th(key, **options) = I18n.t(key, locale: :th, **options)
end
