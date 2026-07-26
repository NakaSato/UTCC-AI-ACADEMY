# One card on the marketing landing page — a topic, a track, a community share,
# an event or an FAQ entry.
#
# Identity, taxonomy and order only, like `Course`: the row says a card exists,
# where it sits and (for a track) what level it is; every word it shows comes
# from `landing.<collection>.<key>.*` in the locale files, with a `LandingText`
# override in front of it. A card an admin created has no shipped copy behind it,
# so for that one the override is all there is — `Landing.copy` handles both.
class LandingCard < ApplicationRecord
  COLLECTIONS = %w[ topics tracks shares events faqs ].freeze

  # The same three words the catalog uses, so a track's badge and a course's
  # badge cannot drift apart.
  LEVELS = %w[ beginner intermediate advanced ].freeze

  # A track cannot exist without a level — it is what the filter chips sort on —
  # but a card is created with only its title, so there is nowhere to have asked
  # for one. It starts at the first level and is changed on the card like
  # everything else about it.
  before_validation(on: :create) { self.level ||= LEVELS.first if track? }

  validates :collection, inclusion: { in: COLLECTIONS }
  validates :key, presence: true, uniqueness: { scope: :collection }
  # A level belongs to a track and to nothing else, and a track is not a track
  # without one — it is what the filter chips sort on.
  validates :level, inclusion: { in: LEVELS }, if: :track?
  validates :level, absence: true, unless: :track?
  validates :weeks, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :in_order, ->(collection) { where(collection:).order(:position, :id) }

  def track? = collection == "tracks"

  # Where a collection's cards sit under `landing.` in the locale files. Two of
  # them nest under `items:` because their section has copy of its own at the
  # level above — `landing.tracks.title` is the section heading, so the tracks
  # themselves cannot also live directly under `tracks`.
  PATHS = {
    "topics" => "topics", "tracks" => "tracks.items", "shares" => "shares",
    "events" => "events.items", "faqs" => "faqs"
  }.freeze

  # The prefix every one of this card's copy keys starts with.
  def prefix = "#{PATHS.fetch(collection)}.#{key}"

  # A new card goes last. Nothing reorders on insert, so a save cannot shuffle
  # the page under an admin who was only adding to it.
  before_create do
    self.position ||= (self.class.where(collection:).maximum(:position) || 0) + 1
  end

  # A card that is gone can have no copy: the key would fail `LandingText`'s
  # whitelist on the next write anyway, so leaving the rows behind would only
  # mean a resurrected key silently inheriting someone else's words.
  after_destroy { LandingText.where("key LIKE ?", "#{prefix}.%").delete_all }

  # Swap places with the neighbour above or below. At either end there is no
  # neighbour, so the move is a no-op rather than an error — the button is not
  # rendered there, and a request that arrives anyway is not worth a flash.
  def move(direction)
    neighbour = self.class.where(collection:)
                    .where(direction.to_s == "up" ? "position < ?" : "position > ?", position)
                    .order(position: direction.to_s == "up" ? :desc : :asc)
                    .first
    return false if neighbour.nil?

    transaction do
      mine = position
      update!(position: neighbour.position)
      neighbour.update!(position: mine)
    end

    true
  end

  # The slug a new card is filed under. It is only ever generated here, never
  # typed: an admin should not have to invent a stable identifier, and this one
  # only has to be unique within its collection.
  #
  # `parameterize` strips non-ASCII, so a Thai-only title yields nothing and
  # falls back to a generic stem — which is why the English title is preferred
  # for the slug even though either may be blank.
  FALLBACK_KEY = "card"

  def self.key_for(collection, *titles)
    stem = titles.compact.map { it.to_s.parameterize }.find(&:present?) || FALLBACK_KEY
    taken = where(collection:).pluck(:key).to_set

    return stem unless taken.include?(stem)

    suffix = 2
    suffix += 1 while taken.include?("#{stem}-#{suffix}")
    "#{stem}-#{suffix}"
  end
end
