require "application_system_test_case"

class InternshipPlacementWalkTest < ApplicationSystemTestCase
  setup do
    @student = users(:student)
    @decider = users(:one)
    @organization = Organization.create!(name: "Walkthrough Logistics", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: @decider, role: "owner")
    @request = @organization.internship_requests.create!(student: @student,
                                                       motivation: "สนใจงานคลังสินค้า",
                                                       learning_goals: "การวิเคราะห์ต้นทุน")
    @request.submit!(actor: @student)
    @request.approve!(actor: @decider)
  end

  test "a company turns an approved request into a running internship" do
    sign_in_through_the_form(@decider)

    visit internship_placements_path
    assert_text th("internship_placements.placeable_heading")
    assert_text @student.name

    click_button th("internship_placements.create")
    assert_text th("flash.internship_placement_created")
    assert_text th("internship_placements.status.planned")
    assert_text th("internship_placements.origin.request")

    click_button th("internship_placements.activate")
    assert_text th("flash.internship_placement_activated")
    assert_text th("internship_placements.status.active")
  end

  test "a placed student files a week and the company acknowledges it" do
    placement = InternshipPlacement.from_request!(@request, actor: @decider)
    placement.activate!(actor: @decider)

    sign_in_through_the_form(@student)

    visit internship_placement_path(placement)
    assert_text th("internship_placements.evidence_notice")

    fill_in "progress_report_activities", with: "เก็บข้อมูลเส้นทาง 12 เส้นทางและสรุปต้นทุนต่อชิ้น"
    fill_in "progress_report_hours", with: "32.5"
    click_button th("internship_placements.submit_report")

    assert_text th("flash.internship_progress_report_submitted")
    assert_text "เก็บข้อมูลเส้นทาง 12 เส้นทางและสรุปต้นทุนต่อชิ้น"
    assert_text th("internship_placements.not_acknowledged")
  end

  private
    def th(key, **options) = I18n.t(key, locale: :th, **options)
end
