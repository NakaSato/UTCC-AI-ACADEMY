require "test_helper"

# The landing page's taxonomy, now that it is rows rather than five frozen
# constants. What matters here is the rules a card obeys whoever is adding one:
# it gets a slug it never has to be given, it goes last, it can be moved, and
# deleting it takes its words with it.
class LandingCardTest < ActiveSupport::TestCase
  test "a new card goes last in its own collection and nowhere else" do
    card = LandingCard.create!(collection: "topics", key: "agents_101")

    assert_equal(LandingCard.in_order("topics").count, card.position)
    assert_equal(6, LandingCard.in_order("tracks").last.position)
  end

  test "the slug comes from the English title" do
    assert_equal("agents-at-work", LandingCard.key_for("topics", "Agents at work", "เอเจนต์"))
  end

  # `parameterize` strips non-ASCII, so a Thai-only title yields nothing to
  # build a slug from. The card still needs one, and it is never shown.
  test "a Thai-only title falls back to a generic slug rather than an empty one" do
    assert_equal(LandingCard::FALLBACK_KEY, LandingCard.key_for("topics", nil, "เอเจนต์"))
  end

  test "a slug already taken in that collection is suffixed until it is not" do
    LandingCard.create!(collection: "topics", key: "ethics-2")

    assert_equal("ethics-3", LandingCard.key_for("topics", "Ethics"))
    # A different collection is a different namespace — the index is scoped.
    assert_equal("ethics", LandingCard.key_for("faqs", "Ethics"))
  end

  test "moving swaps places with the neighbour, and does nothing at either end" do
    first, second = LandingCard.in_order("topics").first(2)

    assert(second.move(:up))
    assert_equal([ second, first ], LandingCard.in_order("topics").first(2))

    assert_not(second.reload.move(:up))
    assert_not(LandingCard.in_order("topics").last.move(:down))
  end

  # A row nothing can render is a row nobody can reach: the key would fail
  # LandingText's whitelist on the next write, so what is left behind could only
  # ever be inherited by a card that happened to reuse the slug.
  test "deleting a card deletes its copy in both languages" do
    card = landing_cards(:topics_prompting)
    LandingText.write("#{card.prefix}.title", :th, "วิศวกรรมพรอมป์")
    LandingText.write("#{card.prefix}.blurb", :en, "Ask better questions")
    other = landing_cards(:topics_ethics)
    LandingText.write("#{other.prefix}.title", :th, "จริยธรรม")

    card.destroy

    assert_empty(LandingText.where("key LIKE ?", "#{card.prefix}.%"))
    assert_equal("จริยธรรม", LandingText.where(key: "#{other.prefix}.title").first.value)
  end

  # A card is created with its title and nothing else, so there was nowhere to
  # ask for a level — and without one a track cannot be saved at all.
  test "a new track starts at the first level rather than refusing to exist" do
    assert_equal("beginner", LandingCard.create!(collection: "tracks", key: "robotics").level)
    assert_nil(LandingCard.create!(collection: "topics", key: "robotics").level)
  end

  test "a level belongs to a track and to nothing else" do
    assert(LandingCard.new(collection: "tracks", key: "x", level: "beginner").valid?)
    assert_not(LandingCard.new(collection: "tracks", key: "x", level: "wizard").valid?)
    # The default only fills a level that was never given, so a track cleared of
    # one is still a track without a level.
    assert_not(LandingCard.new(collection: "tracks", key: "x", level: "").valid?)
    assert_not(landing_cards(:tracks_agents).update(level: nil))
    assert_not(LandingCard.new(collection: "topics", key: "x", level: "beginner").valid?)
  end

  test "a collection the page does not render is not a collection" do
    assert_not(LandingCard.new(collection: "sidebar", key: "x").valid?)
  end

  test "a slug is unique within its collection and free outside it" do
    assert_not(LandingCard.new(collection: "topics", key: "prompting").valid?)
    assert(LandingCard.new(collection: "faqs", key: "prompting").valid?)
  end

  # The fixture, the seeds and the migration are three copies of the same rows.
  # This is the shape all three have to produce; a row added to one and not the
  # others fails here rather than quietly shortening the landing page.
  test "the shipped taxonomy is what the page and the locale files expect" do
    assert_equal(22, LandingCard.count)
    assert_equal([ 6, 6, 3, 3, 4 ],
                 LandingCard::COLLECTIONS.map { LandingCard.in_order(it).size })

    LandingCard::COLLECTIONS.each do |collection|
      positions = LandingCard.in_order(collection).map(&:position)

      assert_equal((1..positions.size).to_a, positions, collection)
    end

    assert_equal(1, LandingCard.in_order("tracks").count { it.weeks.nil? })
    assert_equal(1, LandingCard.in_order("events").count { it.starts_on.present? })
  end
end
