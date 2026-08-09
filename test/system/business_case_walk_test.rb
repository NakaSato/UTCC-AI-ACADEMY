require "application_system_test_case"

# Two walkthroughs rather than one, each with a single sign-in: every other
# system test here signs in once, and switching accounts mid-test only exercises
# the account rail, which is not what this feature is about.
class BusinessCaseWalkTest < ApplicationSystemTestCase
  setup do
    @owner = users(:one)
    @student = users(:student)
    @organization = Organization.create!(name: "Walkthrough Co", creator: users(:admin))
    @organization.memberships.create!(user: @owner, role: "owner")
  end

  test "an owner runs a case from draft through review to closure" do
    sign_in_through_the_form(@owner)

    visit business_cases_path
    click_link th("business_cases.new")
    fill_in "business_case_title", with: "ลดของเสียในคลังสินค้า"
    fill_in "business_case_brief", with: "หาสาเหตุของของเสียและเสนอแนวทาง"
    click_button th("business_cases.save")

    assert_selector "h1", text: "ลดของเสียในคลังสินค้า"
    assert_text th("business_cases.status.draft")
    assert_text th("business_cases.policy_notice")

    click_button th("business_cases.show.publish")
    assert_text th("business_cases.status.published")

    fill_in "milestone_title", with: "สำรวจข้อมูล"
    click_button th("business_cases.show.add_milestone")
    assert_text th("flash.business_case_milestone_created")
    assert_text "สำรวจข้อมูล"

    select @student.name, from: "invitation[user_id]"
    click_button th("business_cases.show.invite_button")
    # The flash, not the student's name: the name is already in the invitee
    # select, so asserting it would match the outgoing document.
    assert_text th("flash.business_case_invitation_sent", name: @student.name)

    # The student's accepted work, seeded so the owner side can review it.
    business_case = BusinessCase.order(:id).last
    business_case.invitations.pending.last.accept!
    business_case.submissions.create!(milestone: business_case.milestones.first, author: @student,
                                      body: "พบว่าของเสียเกิดจากการจัดเก็บผิดชั้น")

    visit business_case_path(business_case)
    assert_text "พบว่าของเสียเกิดจากการจัดเก็บผิดชั้น"
    assert_text th("business_cases.show.version_label", version: 1)

    fill_in "comment_body", with: "ข้อมูลดีมาก ลองเทียบกับไตรมาสก่อน"
    click_button th("business_cases.show.comment_button")
    assert_text th("flash.business_case_comment_created")
    assert_text "ข้อมูลดีมาก ลองเทียบกับไตรมาสก่อน"

    click_button th("business_cases.show.close")
    assert_text th("business_cases.status.closed")
    assert_no_selector "button", text: th("business_cases.show.comment_button")
  end

  test "an invited student accepts from the notification bell and submits work" do
    business_case = @organization.business_cases.create!(owner: @owner, title: "ลดของเสียในคลังสินค้า",
                                                        brief: "หาสาเหตุของของเสียและเสนอแนวทาง")
    business_case.transition_to!("published", actor: @owner)
    business_case.milestones.create!(title: "สำรวจข้อมูล")
    invitation = business_case.invitations.create!(inviter: @owner, invitee: @student)
    Notification.notify(@student, "business_case_invitation", token: invitation.token,
                        business_case: business_case.title, organization: @organization.name)

    sign_in_through_the_form(@student)

    find("button[aria-label='#{th("chrome.notif_toggle")}']").click
    click_link th("notifications.business_case_invitation_action")

    assert_selector "h1", text: th("business_cases.invitation.title")
    assert_text th("business_cases.policy_notice")
    click_button th("business_cases.invitation.accept")

    assert_selector "h1", text: "ลดของเสียในคลังสินค้า"
    assert_text th("flash.business_case_invitation_accepted")

    fill_in "submission_body", with: "พบว่าของเสียเกิดจากการจัดเก็บผิดชั้น"
    click_button th("business_cases.show.submit_button")

    assert_text th("flash.business_case_submission_created", version: 1)
    assert_text "พบว่าของเสียเกิดจากการจัดเก็บผิดชั้น"
    assert_text th("business_cases.show.version_label", version: 1)
  end

  private
    def th(key, **options) = I18n.t(key, locale: :th, **options)
end
