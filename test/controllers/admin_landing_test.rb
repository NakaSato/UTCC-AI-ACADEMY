require "test_helper"

# The seam between the admin editor and the page a stranger reads. The unit
# rules live in landing_text_test.rb; what matters here is that a save reaches
# the landing page, in the language it was written in and no other, and that the
# whitelist holds against a request that did not come from the form.
class AdminLandingTest < ActionDispatch::IntegrationTest
  HEADLINE = "hero.headline"

  setup { sign_in_as users(:admin) }

  test "the editor renders a Thai and an English box for every editable string" do
    get admin_url(tab: :landing)

    assert_response :success
    assert_select "h2", text: I18n.t("admin.landing.title")

    Landing.editable_keys.each do |key|
      I18n.available_locales.each do |locale|
        assert_select "[name=?]", "text[#{key}][#{locale}]", count: 1
      end
    end

    # A track's level and an event's date are the card's, not the copy's.
    LandingCard.in_order("tracks").each { assert_select "[name=?]", "card[#{it.id}][level]", count: 1 }
    LandingCard.in_order("events").each { assert_select "input[type=date][name=?]", "card[#{it.id}][starts_on]" }
  end

  # A form inside a form is dropped by the browser, and the button then silently
  # submits the one it is standing in — a reorder that saves the copy instead.
  # So the copy form does not wrap the cards: its fields name it with `form=`,
  # and each card's own buttons are forms in their own right. Parsing the page
  # is how that is asserted, since the parser drops a nested form exactly as a
  # browser does — if these actions are there, they were never nested.
  test "each card's own controls are forms of their own, not nested in the copy form" do
    card = LandingCard.in_order("topics").second
    get admin_url(tab: :landing, group: "learn")

    assert_select "form[action=?][method=post]", move_admin_landing_card_path(card, dir: :up)
    assert_select "form[action=?][method=post]", admin_landing_card_path(card)
    assert_select "form#landing-learn[action=?]", admin_landing_path
    assert_select "[name=?][form=?]", "text[#{card.prefix}.title][th]", "landing-learn"
    assert_select "input[type=submit][form=?]", "landing-learn"
  end

  test "the shipped copy is the placeholder, so an empty box is not a missing translation" do
    get admin_url(tab: :landing, group: "hero")

    assert_select "[name=?][placeholder=?]", "text[#{HEADLINE}][th]", I18n.t("landing.#{HEADLINE}", locale: :th)
    assert_select "[name=?]:not([value])", "text[#{HEADLINE}][th]"
  end

  test "copy an admin writes is what a signed-out visitor reads, in that language only" do
    patch admin_landing_url, params: { group: "hero", text: { HEADLINE => { th: "เรียน AI ที่ UTCC" } } }

    assert_redirected_to admin_path(tab: :landing, group: "hero")
    assert_equal(I18n.t("flash.landing_saved"), flash[:notice])

    sign_out
    get root_url
    assert_select "h1 .sr-only", text: /เรียน AI ที่ UTCC/

    get root_url(lang: "en")
    assert_select "h1 .sr-only", text: /#{Regexp.escape(I18n.t("landing.#{HEADLINE}", locale: :en))}/
  end

  test "clearing a box puts the shipped copy back" do
    LandingText.write(HEADLINE, :th, "เรียน AI ที่ UTCC")
    patch admin_landing_url, params: { group: "hero", text: { HEADLINE => { th: "" } } }

    assert_empty(LandingText.where(key: HEADLINE))

    sign_out
    get root_url
    assert_select "h1 .sr-only", text: /#{Regexp.escape(I18n.t("landing.#{HEADLINE}", locale: :th))}/
  end

  # A form posts one group, so every other field is absent from the params —
  # absent has to mean "leave alone", not "clear".
  test "saving one group leaves the others alone" do
    LandingText.write("faq_title", :th, "ถามมา ตอบไป")
    patch admin_landing_url, params: { group: "hero", text: { HEADLINE => { th: "เรียน AI ที่ UTCC" } } }

    assert_equal("ถามมา ตอบไป", LandingText.for("faq_title", :th))
  end

  test "a key the page does not render cannot be written by posting it" do
    patch admin_landing_url, params: { group: "hero", text: { "hero.nonesuch" => { th: "x" }, "levels.beginner" => { th: "x" } } }

    assert_redirected_to admin_path(tab: :landing, group: "hero")
    assert_empty(LandingText.all)
  end

  test "an event's date reaches the structured data, and emptying it withdraws the event" do
    patch admin_landing_url, params: { group: "events", card: { workshop.id => { starts_on: "2026-09-01" } } }
    sign_out
    get root_url

    assert_equal([ "2026-09-01" ], published_event_dates)

    sign_in_as users(:admin)
    patch admin_landing_url, params: { group: "events", card: { workshop.id => { starts_on: "" } } }
    sign_out
    get root_url

    assert_empty(published_event_dates)
  end

  # The whole save is one transaction: a level that is not a level must not leave
  # half a group rewritten.
  test "an attribute the card will not accept rejects the whole save" do
    patch admin_landing_url, params: {
      group: "tracks",
      text: { "tracks.title" => { th: "เส้นทางของเรา" } },
      card: { landing_cards(:tracks_agents).id => { level: "wizard" } }
    }

    assert_redirected_to admin_path(tab: :landing, group: "tracks")
    assert(flash[:alert].present?)
    assert_empty(LandingText.all)
    assert_equal("advanced", landing_cards(:tracks_agents).reload.level)
  end

  # ---- Adding, removing and reordering cards --------------------------------

  test "a card an admin adds appears last on the page, in both languages" do
    assert_difference -> { LandingCard.in_order("topics").size }, 1 do
      post admin_landing_cards_url, params: { collection: "topics", title: { th: "เอเจนต์", en: "Agents" } }
    end

    assert_redirected_to admin_path(tab: :landing, group: "learn")
    assert_equal(I18n.t("flash.card_added"), flash[:notice])

    sign_out
    get root_url
    assert_equal("เอเจนต์", landing_topic_titles.last)

    get root_url(lang: "en")
    assert_equal("Agents", landing_topic_titles.last)
  end

  # It has no shipped copy to fall back to, so the language that was filled in is
  # what both pages show — a card an admin added is never invisible.
  test "a card titled in one language shows that title in the other" do
    post admin_landing_cards_url, params: { collection: "topics", title: { th: "เอเจนต์" } }

    sign_out
    get root_url(lang: "en")

    assert_equal("เอเจนต์", landing_topic_titles.last)
  end

  # The add form asks for a title and nothing else, so every collection has to be
  # addable from just that — a track's level is what would otherwise stop it.
  test "every collection can be added to from the title alone" do
    LandingCard::COLLECTIONS.each do |collection|
      assert_difference -> { LandingCard.where(collection:).count }, 1, collection do
        post admin_landing_cards_url, params: { collection:, title: { en: "Robotics" } }
      end

      assert_equal(I18n.t("flash.card_added"), flash[:notice], collection)
    end

    sign_out
    get root_url(lang: "en")
    assert_equal("Robotics", css_select("#tracks article h3").last.text.strip)
  end

  test "a card with no title in either language is not created" do
    assert_no_difference -> { LandingCard.count } do
      post admin_landing_cards_url, params: { collection: "topics", title: { th: "  ", en: "" } }
    end

    assert_equal(I18n.t("flash.card_untitled"), flash[:alert])
  end

  test "a collection the page does not have is not a collection" do
    assert_no_difference -> { LandingCard.count } do
      post admin_landing_cards_url, params: { collection: "sidebar", title: { en: "Ads" } }
    end

    assert_equal(I18n.t("flash.card_invalid"), flash[:alert])
  end

  test "deleting a card takes it off the page and takes its copy with it" do
    card = landing_cards(:topics_ethics)
    LandingText.write("#{card.prefix}.title", :th, "จริยธรรมของ AI")

    delete admin_landing_card_url(card)

    assert_redirected_to admin_path(tab: :landing, group: "learn")
    assert_empty(LandingText.where("key LIKE ?", "#{card.prefix}.%"))

    sign_out
    get root_url
    assert_not_includes(landing_topic_titles, "จริยธรรมของ AI")
    assert_equal(5, landing_topic_titles.size)
  end

  test "reordering moves the card on the page and in the published list" do
    second = LandingCard.in_order("tracks").second

    patch move_admin_landing_card_url(second, dir: :up)

    assert_redirected_to admin_path(tab: :landing, group: "tracks")
    assert_equal(second, LandingCard.in_order("tracks").first)

    sign_out
    get root_url
    assert_equal(Landing.tracks.first.title, published_track_names.first)
  end

  test "a direction that is not a direction moves nothing" do
    before = LandingCard.in_order("tracks").map(&:id)
    patch move_admin_landing_card_url(LandingCard.in_order("tracks").second, dir: "sideways")

    assert_equal(before, LandingCard.in_order("tracks").map(&:id))
  end

  test "a student and an instructor can neither add, remove nor reorder a card" do
    card = landing_cards(:topics_ethics)
    was = card.position

    %i[ student instructor ].each do |role|
      sign_in_as users(role)

      assert_no_difference -> { LandingCard.count } do
        post admin_landing_cards_url, params: { collection: "topics", title: { en: "Ads" } }
        delete admin_landing_card_url(card)
      end

      patch move_admin_landing_card_url(card, dir: :down)
      assert_redirected_to root_path
      assert_equal(was, card.reload.position)
    end
  end

  test "a student cannot rewrite the landing page by posting straight to the endpoint" do
    sign_in_as users(:student)
    patch admin_landing_url, params: { group: "hero", text: { HEADLINE => { th: "x" } } }

    assert_redirected_to root_path
    assert_equal(I18n.t("flash.forbidden"), flash[:alert])
    assert_empty(LandingText.all)
  end

  test "an instructor cannot either" do
    sign_in_as users(:instructor)
    patch admin_landing_url, params: { group: "hero", text: { HEADLINE => { th: "x" } } }

    assert_redirected_to root_path
    assert_empty(LandingText.all)
  end

  test "a request that posts a string where the form posts a hash is ignored rather than fatal" do
    patch admin_landing_url, params: { group: "hero", text: "not-a-hash", date: "not-a-hash" }

    assert_redirected_to admin_path(tab: :landing, group: "hero")
    assert_empty(LandingText.all)
  end

  private
    def workshop = landing_cards(:events_workshop)

    # The topic grid's card titles, in the order the page renders them.
    def landing_topic_titles = css_select("#learn h3").map(&:text).map(&:strip)

    def published_track_names
      css_select("script[type='application/ld+json']")
        .map { JSON.parse(it.text) }
        .select { it["@type"] == "ItemList" }
        .flat_map { it["itemListElement"] }
        .filter_map { it.dig("item", "name") if it.dig("item", "@type") == "Course" }
    end

    def published_event_dates
      css_select("script[type='application/ld+json']")
        .map { JSON.parse(it.text) }
        .select { it["@type"] == "ItemList" }
        .flat_map { it["itemListElement"] }
        .filter_map { it.dig("item", "startDate") }
    end
end
