require "application_system_test_case"

class AcademicPostWalkTest < ApplicationSystemTestCase
  test "a student creates, reopens and edits an academic draft" do
    student = users(:one)
    sign_in_through_the_form(student)

    click_link I18n.t("chrome.nav.writing", locale: :th)
    assert_selector "h1", text: I18n.t("academic.title", locale: :th)

    click_link I18n.t("academic.new", locale: :th)
    fill_in "academic_post_title", with: "บันทึกการเรียนรู้"
    fill_editor "เนื้อหาฉบับร่างแรก"
    click_button I18n.t("academic.save", locale: :th)

    assert_selector "h1", text: "บันทึกการเรียนรู้"
    assert_text "เนื้อหาฉบับร่างแรก"

    click_link I18n.t("academic.edit", locale: :th)
    fill_editor "เนื้อหาฉบับร่างที่แก้ไขแล้ว"
    click_button I18n.t("academic.save", locale: :th)

    assert_selector "h1", text: "บันทึกการเรียนรู้"
    assert_text "เนื้อหาฉบับร่างที่แก้ไขแล้ว"
  end

  private
    def fill_editor(text)
      editor = find('[data-tiptap-target="editor"] [contenteditable="true"]')
      editor.click
      editor.send_keys([ :control, "a" ], text)
    end
end
