# One syllabus string in one language, keyed on something a reorder cannot move.
#
# `Syllabus.topic_name` reads `course.curricula.<CODE>.modules[i].topics[j]` —
# a topic's name is its *position*, with `course_modules.number` and
# `topics.position` as the index. That is fine for a curriculum shipped whole and
# never touched, and it is the reason a teacher cannot be handed a syllabus
# builder: moving one lesson up renames every lesson below it, in Thai and in
# English at once, and adding one leaves a blank where a name should be.
#
# So a topic's name hangs off `topics.key`, which is unique, stable, and what
# every completion row and integrity setting already joins by. Position goes back
# to meaning order.
#
# This is [[LandingText]]'s shape and its rules: for a string that ships with the
# app the row is an **override** — the locale files still hold the copy, still
# render on a fresh install, and a row shadows exactly one string in one
# language. `write` deletes rather than stores when a box is cleared or retyped
# to match the default, so no row can quietly duplicate the file it shadows. For
# a topic somebody added there is nothing to override, and the row is the only
# name that string has.
class SyllabusText < ApplicationRecord
  # A module description is the longest thing here and runs to a sentence or two.
  MAX_LENGTH = 2000

  # `topic.<topic_key>.name`, `module.<COURSE>.<number>.title`, `.desc`. Anchored
  # so a key cannot be smuggled in with a leading or trailing separator.
  KEY_PATTERN = %r{\A(topic\.[A-Za-z0-9\-]+\.name|module\.[A-Z0-9]+\.\d+\.(title|desc))\z}

  validates :value, presence: true, length: { maximum: MAX_LENGTH }
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }
  validates :key, format: { with: KEY_PATTERN }

  class << self
    # ---- Keys ---------------------------------------------------------------

    def topic_key(topic_key) = "topic.#{topic_key}.name"
    def module_title_key(course_code, number) = "module.#{course_code}.#{number}.title"
    def module_desc_key(course_code, number) = "module.#{course_code}.#{number}.desc"

    # ---- Reading ------------------------------------------------------------

    # The whole table, held for the length of one request. A course page names
    # every topic in the syllabus and the builder names them twice, so it is read
    # once and folded in Ruby.
    #
    # On Current rather than in a module memo for the reason Current itself
    # spells out: a process-lifetime memo outlives the database it was read from,
    # and the parallel test runner forks a worker per database.
    def overrides
      Current.syllabus_texts ||= pluck(:key, :locale, :value)
                                   .to_h { |key, locale, value| [ [ key, locale ], value ] }
    end

    # I18n.locale rather than the session's, so an override follows the copy it
    # shadows into whatever locale that copy is being rendered in.
    def for(key, locale = I18n.locale) = overrides[[ key, locale.to_s ]]

    # Whatever language this string was written in, for a topic with no shipped
    # copy to fall back to. Fallback order rather than insertion order, so the
    # answer does not depend on which box was filled first.
    def any(key)
      [ I18n.locale, *I18n.fallbacks[I18n.locale], *I18n.available_locales ]
        .filter_map { self.for(key, it) }
        .first
    end

    # ---- Writing ------------------------------------------------------------

    # A value identical to what the default already says is not a departure from
    # it, so the row goes rather than shadowing the locale file with a copy of
    # itself. A blank box says the same thing — use the default — except where
    # there is no default to fall back to, and then a blank is simply refused:
    # a topic with no name in any language is a lesson nothing can link to.
    def write(key, locale, value, default: nil)
      locale = locale.to_s
      trimmed = value.to_s.strip
      record = find_or_initialize_by(key:, locale:)

      if trimmed.present? && trimmed != default.to_s
        record.update!(value: trimmed)
      elsif default.present?
        record.destroy! if record.persisted?
      else
        record.errors.add(:value, :blank)
        raise ActiveRecord::RecordInvalid, record
      end

      forget
    end

    # Every string for one topic or module, in every language — what a delete
    # takes with it, so a re-used key cannot inherit a dead lesson's name.
    def forget_key(key)
      where(key:).delete_all
      forget
    end

    # The request's copy of the table is stale the moment one is written.
    def forget = Current.syllabus_texts = nil
  end
end
