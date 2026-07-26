# The marketing landing page's content. It used to be Thai string literals inside
# HomeController, which made `/` the one screen that could not be read in English
# and the one controller holding copy; this module puts it back on the same
# footing as every other screen.
#
# Two halves, and they live in different places:
#
#   which cards exist, in what order, a track's level and how many weeks it runs
#     → `landing_cards`, and an admin adds, reorders and deletes them from /admin
#   every word a card shows
#     → `landing.*` in the locale files, with a `landing_texts` override in front
#
# Keys, not positions: a card looks its own copy up by its own slug, so a card
# added to the table without copy written for it renders what the other language
# has rather than silently shifting the card below it.
#
# The locale files are the *default*, not the last word. For a card that ships
# with the app they are what a fresh install renders and what clearing a box
# restores; for a card an admin created there is nothing there at all, and the
# override is the only copy that string has. `copy` reads both the same way.
module Landing
  # `all` is the default and has no level of its own; the rest are the levels a
  # track can carry, so their labels come from `levels.*` rather than a second
  # copy of the same three words. Not a card collection — these are the filter
  # chips, and they are the same three words the catalog uses.
  TRACK_FILTERS = %i[ all beginner intermediate advanced ].freeze

  # Copy that is a sentence rather than a phrase, named by the last segment of
  # its path — a blurb is a blurb wherever it appears. The editor gives these a
  # textarea and the rest a one-line field.
  LONG_FIELDS = %w[ lede disclaimer blurb subtitle a ].freeze

  Topic = Data.define(:key) do
    def title = Landing.copy("topics.#{key}.title")
    def blurb = Landing.copy("topics.#{key}.blurb")
  end

  Track = Data.define(:key, :level, :weeks) do
    def title = Landing.copy("tracks.items.#{key}.title")
    def blurb = Landing.copy("tracks.items.#{key}.blurb")

    # `levels.*` and `units.*` are shared chrome — the catalog and the progress
    # screen read the same three words — so they stay plain lookups rather than
    # something the landing editor can reword out from under another screen.
    def level_label = I18n.t("levels.#{level}")

    # A track with no week count is continuous rather than zero weeks long.
    def duration = weeks ? I18n.t("units.weeks", count: weeks) : Landing.copy("tracks.ongoing")
  end

  Share = Data.define(:key) do
    def title = Landing.copy("shares.#{key}.title")
    def author = Landing.copy("shares.#{key}.author")
    def tag = Landing.copy("shares.#{key}.tag")
    # A date, not a Date: Thai writes the Buddhist year, which no strftime of a
    # Gregorian date produces. The card's `starts_on` column is the other one.
    def date = Landing.copy("shares.#{key}.date")
  end

  Event = Data.define(:key, :starts_on) do
    def title = Landing.copy("events.items.#{key}.title")
    def when_label = Landing.copy("events.items.#{key}.when")
    def where_label = Landing.copy("events.items.#{key}.where")

    # A recurring event has no one date, so it has nothing to publish.
    def dated? = starts_on.present?
  end

  Question = Data.define(:key) do
    def question = Landing.copy("faqs.#{key}.q")
    def answer = Landing.copy("faqs.#{key}.a")
  end

  Filter = Data.define(:key) do
    def label = key == :all ? Landing.copy("tracks.filter_all") : I18n.t("levels.#{key}")
  end

  # One group of the editor, which is one section of the page: the section's own
  # key, the paths it owns that belong to no card, and the cards under it.
  Group = Data.define(:key, :collection, :fields, :cards)

  # One card in the editor: the row, and the copy paths that hang off it.
  CardFields = Data.define(:record, :fields) do
    def id = record.id
    def prefix = record.prefix
  end

  class << self
    def topics = cards("topics").map { Topic.new(key: it.key) }

    def tracks = cards("tracks").map { Track.new(key: it.key, level: it.level.to_sym, weeks: it.weeks) }

    def track_filters = TRACK_FILTERS.map { Filter.new(key: it) }

    def shares = cards("shares").map { Share.new(key: it.key) }

    def events = cards("events").map { Event.new(key: it.key, starts_on: it.starts_on&.to_s) }

    def faqs = cards("faqs").map { Question.new(key: it.key) }

    # Every card, in order, read once per request and grouped in Ruby — one query
    # for a page that asks for five collections. Held on Current for the reason
    # Current itself spells out: a module memo outlives the database it was read
    # from, and the parallel test runner forks a worker per database.
    def cards(collection)
      all_cards = Current.landing_cards ||= LandingCard.order(:position, :id).group_by(&:collection)

      all_cards.fetch(collection, [])
    end

    def forget_cards = Current.landing_cards = nil

    # One string of the page, in the language being rendered: what an admin wrote
    # here, then what ships in this language, then what an admin wrote in the
    # other one.
    #
    # That last step is what keeps a card an admin added visible in both
    # languages. It has no shipped copy to fall back to, so a translation nobody
    # has written yet shows the language that has one rather than a hole in the
    # page — and a `Course` or `Event` node with a blank `name` never ships. For
    # a card that does ship, the second step answers first, so a Thai-only
    # override still never displaces the English the app came with.
    def copy(key) = LandingText.for(key) || default(key).presence || LandingText.any(key).to_s

    # What `copy` would return with no override at all — what the editor shows as
    # a placeholder, and what a value has to match to be discarded rather than
    # stored as a duplicate of it. `nil` for a card that ships with nothing:
    # without the explicit default, I18n would answer "translation missing" and
    # the page would render it.
    def default(key, locale = I18n.locale) = I18n.t("landing.#{key}", locale:, default: nil)

    # The editable page, section by section, in the order it reads. Chrome is not
    # here on purpose: `landing.brand_*`, `landing.nav.*` and `hero.logo_alt`
    # belong to shared/_header, which is on screens this editor is not about.
    #
    # Derived from the cards rather than written out, so a card an admin adds
    # arrives in the editor with copy fields of its own and no second edit.
    def groups
      [
        group("hero", nil, %w[ headline lede cta_learn cta_community disclaimer ], []),
        group("learn", "topics", %w[ eyebrow title subtitle card_cta ], %w[ title blurb ]),
        group("tracks", "tracks", %w[ title subtitle filter_label filter_all ongoing card_cta ], %w[ title blurb ]),
        group("community", "shares", %w[ title subtitle cta ], %w[ title author tag date ]),
        group("events", "events", %w[ title ], %w[ title when where ]),
        group("faq", "faqs", [], %w[ q a ])
      ]
    end

    def group_for(key) = groups.find { it.key == key.to_s }

    # Every copy path an admin may rewrite — the whitelist LandingText validates
    # against and the controller reads params through.
    def editable_keys = groups.flat_map { [ *it.fields, *it.cards.flat_map(&:fields) ] }

    # A field is named by the last segment of its path, so a blurb is labelled
    # and sized the same wherever it appears rather than once per card.
    def field_name(key) = key.split(".").last

    # Copy that is a sentence rather than a phrase, and wants a textarea.
    def long?(key) = LONG_FIELDS.include?(field_name(key))

    # How the editor names one card: by its own current title, which is what an
    # admin would recognise it as. An FAQ has no title, so it is named by its
    # question — and a card with copy in neither language has nothing to be
    # called yet, so it says so with its slug.
    def card_label(card)
      %w[ title q ].each do |name|
        next unless card.fields.any? { field_name(it) == name }

        label = copy("#{card.prefix}.#{name}")
        return label if label.present?
      end

      card.record.key
    end

    private
      # `faq_title` is the odd one out — the FAQ section's heading sits at the
      # root of `landing.` rather than under a section key of its own.
      def section_fields(key, names)
        key == "faq" ? [ "faq_title" ] : names.map { "#{key}.#{it}" }
      end

      def group(key, collection, names, card_names)
        cards = collection ? cards(collection).map { card_fields(it, card_names) } : []

        Group.new(key:, collection:, fields: section_fields(key, names), cards:)
      end

      def card_fields(record, names)
        CardFields.new(record:, fields: names.map { "#{record.prefix}.#{it}" })
      end
  end
end
