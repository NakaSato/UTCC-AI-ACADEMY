class CreateLandingCards < ActiveRecord::Migration[8.1]
  # The landing page's taxonomy — which cards exist, in what order — as rows.
  # It used to be five frozen constants in `Landing`, which meant adding a topic
  # or retiring an event was a deploy. `landing_texts` had already made the
  # page's words editable; this is what makes the page itself editable.
  #
  # Copy is deliberately NOT here, same as `courses`. A card carries identity,
  # taxonomy and numbers; every word a human reads is still `landing.<collection>
  # .<key>.*` in the locale files, with a `landing_texts` override in front of it.
  # A card an admin adds has no shipped copy, so for that one the override is all
  # there is — see `Landing.copy`.
  #
  # An event's date IS here, as a column, because it is not copy: it is one fact
  # in both languages. It lived briefly as a `landing_texts` row under a reserved
  # locale, which was only ever a workaround for there being no card to put it on.

  # collection, key, then the collection's own attributes.
  TOPICS = %w[ what_is_ai prompting machine_learning build_apps ethics business ].freeze

  # key, level, weeks — nil weeks where the track is open-ended.
  TRACKS = [
    [ "beginners",     "beginner",     4 ],
    [ "engineering",   "beginner",     6 ],
    [ "first_project", "intermediate", 8 ],
    [ "data_ml",       "intermediate", 8 ],
    [ "agents",        "advanced",     10 ],
    [ "research",      "advanced",     nil ]
  ].freeze

  SHARES = %w[ chatbot free_tools neural_net ].freeze

  # key, then the calendar date where there is one. The copy says when an event
  # happens in words, and in two calendars since Thai writes the Buddhist year;
  # this is the same fact in the form the structured data can use. `nil` for the
  # two that recur rather than happen once.
  EVENTS = [ [ "study_jam", nil ], [ "workshop", "2026-08-08" ], [ "show_and_tell", nil ] ].freeze

  FAQS = %w[ no_background homework share_project other_faculties ].freeze

  def up
    create_table :landing_cards do |t|
      t.string  :collection, null: false
      # The slug the copy is filed under: `landing.topics.<key>.title` in the
      # locale files, and the first half of every `landing_texts.key` for it.
      t.string  :key, null: false
      t.integer :position, null: false
      # Tracks only. Nullable rather than a table of their own: three optional
      # columns across five collections is less machinery than five tables, and
      # each is validated against the collection that owns it.
      t.string  :level
      t.integer :weeks
      # Events only. A real date, unlike the words beside it.
      t.date    :starts_on

      t.timestamps
    end

    add_index :landing_cards, %i[ collection key ], unique: true
    add_index :landing_cards, %i[ collection position ]

    seed
  end

  def down
    drop_table :landing_cards
  end

  private
    # Reference data, so the migration writes it rather than db/seeds.rb — seeds
    # are fenced to Rails.env.local? and production would otherwise come up with
    # a landing page that has no cards on it at all.
    def seed
      now = Time.current
      rows = []

      { "topics" => TOPICS, "shares" => SHARES, "faqs" => FAQS }.each do |collection, keys|
        keys.each_with_index { |key, index| rows << { collection:, key:, position: index + 1 } }
      end

      TRACKS.each_with_index do |(key, level, weeks), index|
        rows << { collection: "tracks", key:, position: index + 1, level:, weeks: }
      end

      EVENTS.each_with_index do |(key, starts_on), index|
        rows << { collection: "events", key:, position: index + 1, starts_on: }
      end

      # insert_all wants every row to carry the same keys, and most collections
      # have no level, weeks or date of their own.
      blank = { level: nil, weeks: nil, starts_on: nil, created_at: now, updated_at: now }

      table("landing_cards").insert_all(rows.map { blank.merge(it) })
    end

    # Throwaway class rather than LandingCard: a migration has to keep working
    # when the app's models move on without it.
    def table(name) = Class.new(ActiveRecord::Base) { self.table_name = name }
end
