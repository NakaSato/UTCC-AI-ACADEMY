require "test_helper"

# Which language a page renders in, and in what order the three sources decide:
# `?lang=`, then the toggle's session, then the browser's Accept-Language. The
# rule matters most for the visitor who never gets to use the toggle — a crawler,
# and a student on their very first request.
class LocaleNegotiationTest < ActionDispatch::IntegrationTest
  setup { sign_out }

  test "the browser's language decides when nothing else has" do
    expected = {
      "en-GB,en;q=0.9" => "en",
      "th-TH,th;q=0.9,en;q=0.8" => "th",
      # Read in quality order rather than in the order it was written, and past
      # the languages the site does not have.
      "fr;q=1.0,th;q=0.2,en;q=0.8" => "en",
      "fr-FR,fr;q=0.9" => "th"
    }

    assert_equal expected, expected.keys.index_with { locale_for(headers: { "Accept-Language" => it }) }
  end

  test "an absent or unparsable header leaves Thai" do
    [ nil, "", ";;;", "*" ].each do |header|
      assert_equal "th", locale_for(headers: { "Accept-Language" => header }.compact), header.inspect
    end
  end

  test "the toggle outranks the browser" do
    post language_path("th")

    assert_equal "th", locale_for(headers: { "Accept-Language" => "en-US,en;q=0.9" })
  end

  test "lang outranks the toggle" do
    post language_path("th")

    assert_equal "en", locale_for(params: { lang: "en" })
  end

  # The param is a URL for one language, not a way to set a preference: it is
  # read for one request and never written to the session, so Turbo prefetching
  # a link cannot change what the visitor is reading.
  test "lang lasts exactly one request" do
    assert_equal "en", locale_for(params: { lang: "en" })
    assert_equal "th", locale_for
  end

  test "an unknown lang is ignored rather than raising" do
    assert_equal "th", locale_for(params: { lang: "fr" })
    assert_response :success
  end

  test "the whole app answers in the negotiated language, not just the landing page" do
    sign_in_as users(:one)
    get progress_path, headers: { "Accept-Language" => "en" }

    assert_select "html[lang=?]", "en"
    assert_select "h1", text: I18n.t("progress.greeting", name: users(:one).first_name, locale: :en)
  end

  private
    # The <html lang> attribute is the one place every layout states the answer.
    def locale_for(path: root_path, **options)
      get path, **options
      css_select("html").first["lang"]
    end
end
