require "test_helper"

# robots.txt, the sitemap and llms.txt are the only pages written for a machine,
# and the only three rendered from Rails purely so they can name absolute URLs.
# What matters is that a crawler can reach them without a session, that they agree
# with each other about which pages are public, and that they never advertise a
# path that answers a redirect.
class CrawlersTest < ActionDispatch::IntegrationTest
  PATHS = %w[/robots.txt /sitemap.xml /llms.txt].freeze

  test "all three are readable without an account" do
    sign_out

    PATHS.each do |path|
      get path

      assert_response :success, path
      assert response.body.present?, "#{path} is empty"
    end
  end

  test "robots names the sitemap and closes the private area" do
    get robots_path

    assert_match(/^Sitemap: #{Regexp.escape(sitemap_url)}$/, response.body)

    CrawlersController::DISALLOWED.each do |path|
      assert_match(/^Disallow: #{Regexp.escape(path)}$/, response.body, path)
    end
  end

  # A named group replaces the wildcard rather than adding to it, so the model
  # crawlers only get the same treatment as everyone else if the rules are
  # repeated under their names.
  test "the model crawlers are named and carry the wildcard's rules" do
    get robots_path

    CrawlersController::AI_AGENTS.each do |agent|
      assert_match(/^User-agent: #{Regexp.escape(agent)}$/, response.body, agent)
    end

    # Consecutive User-agent lines share one record, so the groups are the blocks
    # between blank lines rather than one per agent named.
    groups = response.body.split(/\n{2,}/).select { it.start_with?("User-agent:") }
    rules = groups.map { it.scan(/^(?:Allow|Disallow): .+$/) }

    assert_equal 2, rules.size, "expected a wildcard group and a group for the named agents"
    assert_equal rules.first, rules.last
    assert_includes rules.first, "Allow: /"
    assert_equal CrawlersController::AI_AGENTS.size, groups.last.scan(/^User-agent:/).size
  end

  test "the sitemap lists every public page in every language and nothing behind the login" do
    get sitemap_path

    # Scanned rather than selected: the entries carry namespaced xhtml:link
    # children, and what they are is more legible as text than as a DOM query.
    locations = response.body.scan(%r{<loc>(.+?)</loc>}).flatten
    expected = [ root_url, privacy_url, terms_url ].flat_map { [ it, "#{it}?lang=en" ] }

    assert_equal expected.sort, locations.sort
    CrawlersController::DISALLOWED.each do |path|
      assert_empty locations.grep(/#{Regexp.escape(path)}/), "#{path} should not be in the sitemap"
    end
  end

  # A cluster that does not name every member of itself, itself included, is
  # discarded whole rather than read partially.
  test "every sitemap entry names all of its translations" do
    get sitemap_path

    entries = response.body.scan(%r{<url>.*?</url>}m)

    assert_equal 6, entries.size
    entries.each do |entry|
      I18n.available_locales.each do |locale|
        assert_match(/hreflang="#{locale}"/, entry, entry)
      end
      assert_match(/hreflang="x-default"/, entry, entry)
    end
  end

  test "llms.txt describes the site in English whatever the session's locale is" do
    post language_path("th")
    get llms_path

    I18n.with_locale(:en) do
      assert_includes response.body, Landing.topics.first.title
      assert_includes response.body, Landing.tracks.first.blurb
    end

    # ...and it says so, since the pages it points at answer in Thai by default.
    assert_includes response.body, "Thai-first"
  end

  test "llms.txt carries every landing card and every public URL" do
    get llms_path

    I18n.with_locale(:en) do
      (Landing.topics + Landing.tracks).each do |card|
        assert_includes response.body, card.title
      end

      Landing.faqs.each do |question|
        assert_includes response.body, question.question
        assert_includes response.body, question.answer
      end
    end

    # The pages are linked in the language the file is written in.
    [ root_url, privacy_url, terms_url ].each do |url|
      assert_includes response.body, "#{url}?lang=en"
    end
    assert_includes response.body, sitemap_url
  end
end
