require "test_helper"

# The JSON-LD is the only part of a page written for something that will never
# look at it — so nothing on screen breaks when it is wrong. These are the
# assertions that would otherwise be a trip to a validator.
class StructuredDataTest < ActionDispatch::IntegrationTest
  test "the landing page publishes the school, its tracks, its FAQ and its events" do
    sign_out
    get root_path

    assert_equal %w[EducationalOrganization FAQPage ItemList ItemList], types.sort
    assert list(I18n.t("landing.tracks.title")), "the tracks are not published"
    assert list(I18n.t("landing.events.title")), "the events are not published"
  end

  test "every FAQ answer on the page is also an answer in the data" do
    sign_out
    get root_path

    questions = schema("FAQPage")["mainEntity"]

    assert_equal Landing.faqs.size, questions.size
    Landing.faqs.zip(questions).each do |source, published|
      assert_equal source.question, published["name"]
      assert_equal source.answer, published.dig("acceptedAnswer", "text")
    end
  end

  test "the tracks keep their order and name the school by reference" do
    sign_out
    get root_path

    items = list(I18n.t("landing.tracks.title"))["itemListElement"]

    assert_equal (1..Landing.tracks.size).to_a, items.map { it["position"] }
    assert_equal Landing.tracks.map(&:title), items.map { it.dig("item", "name") }

    items.each do |entry|
      assert_equal schema("EducationalOrganization")["@id"], entry.dig("item", "provider", "@id")
    end
  end

  # An open-ended track has no week count, and a duration of "P" would be invalid
  # rather than merely vague.
  test "a track's duration is published only when it has one" do
    sign_out
    get root_path

    durations = list(I18n.t("landing.tracks.title"))["itemListElement"].map { it["item"]["timeRequired"] }

    assert_equal Landing.tracks.map { it.weeks && "P#{it.weeks}W" }, durations
  end

  # "Every Wednesday" is a real answer for a human and no answer at all for
  # startDate, so the recurring events are left out rather than given a date.
  test "only the events with a date are published, and they carry one" do
    sign_out
    get root_path

    events = list(I18n.t("landing.events.title"))["itemListElement"].map { it["item"] }
    dated = Landing.events.select(&:dated?)

    assert dated.any?, "the fixture data has no dated event left to test"
    assert_equal dated.map(&:title), events.map { it["name"] }
    assert_equal dated.map(&:starts_on), events.map { it["startDate"] }
    events.each do |event|
      assert_equal "Place", event.dig("location", "@type")
      assert event["location"]["name"].present?
    end
  end

  test "the data is translated with the page" do
    %w[th en].each do |locale|
      post language_path(locale)
      get root_path

      I18n.with_locale(locale) do
        assert_equal Landing.faqs.first.question, schema("FAQPage")["mainEntity"].first["name"]
        assert_equal I18n.t("meta.org_name"), schema("EducationalOrganization")["name"]
        assert list(I18n.t("landing.tracks.title")), "the tracks list is not named in #{locale}"
      end
    end
  end

  # The FAQ, the tracks and the events belong to the landing page, not to the
  # layout — a signed-in screen has nothing of its own to declare.
  test "a screen behind the login publishes the school and nothing else" do
    sign_in_as users(:one)
    get progress_path

    assert_equal %w[EducationalOrganization], types
  end

  private
    def documents
      css_select("script[type='application/ld+json']").map { JSON.parse(it.text) }
    end

    def types = documents.map { it["@type"] }

    def schema(type) = documents.find { it["@type"] == type }

    # Two ItemLists share a page, so a list is found by the section it came from.
    def list(name) = documents.find { it["@type"] == "ItemList" && it["name"] == name }
end
