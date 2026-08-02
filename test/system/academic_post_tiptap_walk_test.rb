require "application_system_test_case"

class AcademicPostTiptapWalkTest < ApplicationSystemTestCase
  test "inserts and renders an inline math node" do
    student = users(:one)
    sign_in_through_the_form(student)

    click_link I18n.t("chrome.nav.writing", locale: :th)
    click_link I18n.t("academic.new", locale: :th)
    fill_in "academic_post_title", with: "สมการพื้นฐาน"
    accept_prompt("Enter a LaTeX expression", with: "E=mc^2") do
      find('[data-action="tiptap#insertMath"]').click
    end

    assert_selector '[data-tiptap-target="editor"] [data-type="inline-math"][data-latex="E=mc^2"]'
    assert_includes find("#academic_post_body", visible: false).value, "data-latex=\"E=mc^2\""
    click_button I18n.t("academic.save", locale: :th)

    assert_selector "h1", text: "สมการพื้นฐาน"
    assert_selector '[data-tiptap-target="editor"] [data-type="inline-math"][data-latex="E=mc^2"]'
    assert_selector ".katex"
  end
end
