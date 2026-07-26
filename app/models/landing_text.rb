# One string on the marketing landing page, in one language, as an admin wrote it.
#
# For a card that ships with the app this is an *override*: `config/locales/{th,en}.yml`
# still holds the copy and is still what a fresh install renders, and a row here
# shadows one string in one language. Which is why `write` deletes rather than
# stores when a box is cleared or retyped to match the default — there is no
# state in which a row silently duplicates the locale file it shadows.
#
# For a card an admin created there is nothing to override: the row is the only
# copy that string has. `Landing.copy` reads both the same way, and falls back to
# the other language rather than leaving a new card blank in one of them.
#
# `key` is the path under `landing.` — "topics.prompting.title" — and is checked
# against the whitelist `Landing` derives from the cards, so an override for a
# string nothing renders cannot be written.
class LandingText < ApplicationRecord
  # Long enough for the longest FAQ answer several times over, short enough that
  # the landing page cannot be turned into a document.
  MAX_LENGTH = 2000

  validates :value, presence: true, length: { maximum: MAX_LENGTH }
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }
  validate :key_is_editable

  class << self
    # The whole table, held for the length of one request. The landing page reads
    # something like a hundred strings and the admin editor twice that, so it is
    # read once and folded in Ruby.
    #
    # On Current rather than in a module memo for the reason spelled out in
    # Current itself: a process-lifetime memo outlives the database it was read
    # from, and the parallel test runner forks a worker per database.
    def overrides
      Current.landing_texts ||= pluck(:key, :locale, :value).to_h { |key, locale, value| [ [ key, locale ], value ] }
    end

    # I18n.locale rather than the session's: llms.txt renders inside
    # `I18n.with_locale(:en)` whatever language the reader is browsing in, and
    # the override has to follow the copy it shadows.
    def for(key, locale = I18n.locale) = overrides[[ key, locale.to_s ]]

    # Whatever language this string was written in, for a card that has no
    # shipped copy to fall back to. Fallback order, not insertion order, so the
    # answer does not depend on which box an admin filled first.
    def any(key)
      [ I18n.locale, *I18n.fallbacks[I18n.locale], *I18n.available_locales ]
        .filter_map { self.for(key, it) }
        .first
    end

    # A value identical to what the default already says is not a departure from
    # it, so the row goes rather than shadowing the locale file with a copy of
    # itself. A blank box says the same thing — use the default — which is what
    # makes clearing one the reset button, and needs no second control.
    def write(key, locale, value)
      locale = locale.to_s
      trimmed = value.to_s.strip
      record = find_or_initialize_by(key:, locale:)

      if trimmed.blank? || trimmed == Landing.default(key, locale).to_s
        record.destroy! if record.persisted?
      else
        record.update!(value: trimmed)
      end

      forget
    end

    # The request's copy of the table is stale the moment one is written.
    def forget = Current.landing_texts = nil
  end

  private
    def key_is_editable
      errors.add(:key, :inclusion) unless Landing.editable_keys.include?(key)
    end
end
