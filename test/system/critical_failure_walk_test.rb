require "application_system_test_case"

class CriticalFailureWalkTest < ApplicationSystemTestCase
  test "password reset remains generic and does not expose operational telemetry" do
    visit forgot_password_path

    fill_in I18n.t("auth.fields.email"), with: "missing-user@example.com"
    click_button I18n.t("auth.forgot.submit")

    assert_text I18n.t("auth.forgot.sent_title")
    assert_no_text "SMTP"
    assert_no_text "observability"
    assert_no_text "[REDACTED]"
  end

  test "password reset remains generic in English" do
    visit forgot_password_path
    find("button", text: "EN", exact_text: true).click

    fill_in I18n.t("auth.fields.email", locale: :en), with: "missing-user@example.com"
    click_button I18n.t("auth.forgot.submit", locale: :en)

    assert_text I18n.t("auth.forgot.sent_title", locale: :en)
    assert_no_text "SMTP"
    assert_no_text "observability"
  end
end
