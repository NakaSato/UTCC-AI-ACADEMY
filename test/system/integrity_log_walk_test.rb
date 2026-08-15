require "application_system_test_case"

# User-requested acceptance walk: integrity feedback belongs only to the two
# assessed lesson steps, and its durable record must survive both a browser
# refresh and a locale-changing navigation.
class IntegrityLogWalkTest < ApplicationSystemTestCase
  test "stored incidents return only on assessment steps and follow the selected language" do
    student = users(:one)
    ProctorEvent.create!(user: student, course: courses(:ai1101), topic: topics(:topic_1_1),
                         kind: "blur", occurred_at: Time.current)
    sign_in_through_the_form(student)

    visit lesson_path(course: "AI1101", topic: "1-1", step: :theory)
    assert_no_selector "[data-integrity-log]", visible: true

    find("[role=tab][data-panel=exercise]").click
    assert_selector "[data-integrity-log]", visible: true,
                    text: I18n.t("lesson.proctor.events.blur", locale: :th)

    page.refresh
    assert_selector "[data-integrity-log]", visible: true,
                    text: I18n.t("lesson.proctor.events.blur", locale: :th)

    find("button[aria-label='#{I18n.t("chrome.user_toggle", locale: :th)}']").click
    within("[data-menu=account]") do
      find("[data-preference=language] > button").click
      find("form[action='#{language_path(:en)}'] button").click
    end

    assert_selector "html[lang=en]"
    assert_selector "[data-integrity-log]", visible: true,
                    text: I18n.t("lesson.proctor.events.blur", locale: :en)

    find("[role=tab][data-panel=summary]").click
    assert_no_selector "[data-integrity-log]", visible: true

    find("[role=tab][data-panel=code]").click
    assert_selector "[data-integrity-log]", visible: true,
                    text: I18n.t("lesson.proctor.events.blur", locale: :en)
  end
end
