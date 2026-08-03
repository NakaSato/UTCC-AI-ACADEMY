require "test_helper"

# What each page tells a search engine about itself: which URL it is, where its
# translations are, and whether it wants to be listed at all. None of it is
# visible, so none of it fails loudly.
class IndexingTest < ActionDispatch::IntegrationTest
  test "a page is canonical to its own translation, not to the path" do
    sign_out

    get root_path
    assert_select "link[rel=canonical][href=?]", root_url

    get root_path, params: { lang: "en" }
    assert_select "link[rel=canonical][href=?]", "#{root_url}?lang=en"
  end

  # Screen state is not a page. /leaderboard?tab=week and /leaderboard are one
  # URL as far as an index is concerned, and saying otherwise splits it.
  test "the canonical drops every param but the language" do
    sign_in_as users(:one)
    FeatureSetting.find_by!(key: "leaderboard").update!(enabled: true)
    get leaderboard_path(tab: "semester")

    assert_select "link[rel=canonical][href=?]", leaderboard_url
  end

  # Every URL this app publishes is built from request.base_url, so the scheme is
  # whatever Rails believes the request arrived on. In production that belief
  # comes from `config.assume_ssl`, since Kamal's proxy terminates TLS and speaks
  # http to Thruster — turn it off and the site starts announcing canonical URLs
  # for pages it does not serve.
  test "the URLs a page publishes follow the scheme it was reached on" do
    sign_out
    https!
    get root_path

    assert_select "link[rel=canonical][href=?]", "https://www.example.com/"
    assert_select "link[rel=alternate][hreflang=en][href=?]", "https://www.example.com/?lang=en"
  end

  test "every public page names its translations and a default" do
    sign_out

    [ root_path, privacy_path, terms_path ].each do |path|
      get path

      published = css_select("link[rel=alternate]").to_h { [ it["hreflang"], it["href"] ] }
      # Thai is what a visitor with no matching language gets, so Thai is the
      # x-default here too — the same rule switch_locale applies.
      expected = { "th" => "#{request.base_url}#{path}", "en" => "#{request.base_url}#{path}?lang=en" }

      assert_equal expected.merge("x-default" => expected["th"]), published, path
    end
  end

  test "the alternates are the same set whichever translation is being read" do
    sign_out

    thai = alternates_on(root_path)
    get root_path, params: { lang: "en" }

    assert_equal thai, css_select("link[rel=alternate]").map { it["href"] }
  end

  test "the social card names the other language too" do
    sign_out
    get root_path

    assert_select "meta[property='og:locale'][content=?]", I18n.t("meta.og_locale", locale: :th)
    assert_select "meta[property='og:locale:alternate'][content=?]", I18n.t("meta.og_locale", locale: :en)
  end

  # robots.txt keeps a crawler off these; this keeps them out of an index they
  # reached by a link from somewhere else.
  test "the auth screens ask not to be indexed" do
    sign_out

    [ login_path, register_path, forgot_password_path ].each do |path|
      get path

      assert_equal [ "noindex, nofollow" ], css_select("meta[name=robots]").map { it["content"] }, path
    end
  end

  test "the pages that are meant to be found do not" do
    sign_out

    [ root_path, privacy_path, terms_path ].each do |path|
      get path

      assert_select "meta[name=robots]", false, "#{path} should not be asking to be left out"
    end
  end

  private
    def alternates_on(path)
      get path
      css_select("link[rel=alternate]").map { it["href"] }
    end
end
