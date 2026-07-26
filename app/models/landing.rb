# The marketing landing page's content. It used to be Thai string literals inside
# HomeController, which made `/` the one screen that could not be read in English
# and the one controller holding copy; this module puts it back on the same
# footing as every other screen.
#
# Ruby holds the taxonomy — which cards exist, in what order, a track's level and
# how many weeks it runs. Every word is in `landing.*` in the locale files.
#
# Keys, not positions: a card looks its own copy up by name, so adding one here
# without writing its copy renders a missing translation instead of silently
# shifting the card below it.
module Landing
  TOPICS = %i[ what_is_ai prompting machine_learning build_apps ethics business ].freeze

  # level, then how many weeks it runs — nil where the track is open-ended.
  TRACKS = {
    beginners:     [ :beginner,     4 ],
    engineering:   [ :beginner,     6 ],
    first_project: [ :intermediate, 8 ],
    data_ml:       [ :intermediate, 8 ],
    agents:        [ :advanced,     10 ],
    research:      [ :advanced,     nil ]
  }.freeze

  # `all` is the default and has no level of its own; the rest are the levels a
  # track can carry, so their labels come from `levels.*` rather than a second
  # copy of the same three words.
  TRACK_FILTERS = %i[ all beginner intermediate advanced ].freeze

  SHARES = %i[ chatbot free_tools neural_net ].freeze
  EVENTS = %i[ study_jam workshop show_and_tell ].freeze
  FAQS   = %i[ no_background homework share_project other_faculties ].freeze

  Topic = Data.define(:key) do
    def title = I18n.t("landing.topics.#{key}.title")
    def blurb = I18n.t("landing.topics.#{key}.blurb")
  end

  Track = Data.define(:key, :level, :weeks) do
    def title = I18n.t("landing.tracks.items.#{key}.title")
    def blurb = I18n.t("landing.tracks.items.#{key}.blurb")

    def level_label = I18n.t("levels.#{level}")

    # A track with no week count is continuous rather than zero weeks long.
    def duration = weeks ? I18n.t("units.weeks", count: weeks) : I18n.t("landing.tracks.ongoing")
  end

  Share = Data.define(:key) do
    def title = I18n.t("landing.shares.#{key}.title")
    def author = I18n.t("landing.shares.#{key}.author")
    def tag = I18n.t("landing.shares.#{key}.tag")
    # A date, not a Date: Thai writes the Buddhist year, which no strftime of a
    # Gregorian date produces.
    def date = I18n.t("landing.shares.#{key}.date")
  end

  Event = Data.define(:key) do
    def title = I18n.t("landing.events.items.#{key}.title")
    def when_label = I18n.t("landing.events.items.#{key}.when")
    def where_label = I18n.t("landing.events.items.#{key}.where")
  end

  Question = Data.define(:key) do
    def question = I18n.t("landing.faqs.#{key}.q")
    def answer = I18n.t("landing.faqs.#{key}.a")
  end

  Filter = Data.define(:key) do
    def label = key == :all ? I18n.t("landing.tracks.filter_all") : I18n.t("levels.#{key}")
  end

  class << self
    def topics = TOPICS.map { Topic.new(key: it) }

    def tracks = TRACKS.map { |key, (level, weeks)| Track.new(key:, level:, weeks:) }

    def track_filters = TRACK_FILTERS.map { Filter.new(key: it) }

    def shares = SHARES.map { Share.new(key: it) }

    def events = EVENTS.map { Event.new(key: it) }

    def faqs = FAQS.map { Question.new(key: it) }
  end
end
