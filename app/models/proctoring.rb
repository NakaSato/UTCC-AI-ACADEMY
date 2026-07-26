# Academic-integrity monitoring for the lesson screen.
#
# The watching still happens in the browser (see the `proctor` Stimulus
# controller), but each incident is now posted to `lesson/incident` and kept in
# `proctor_events` — the sidebar's score is still per-page theatre, while the
# admin Integrity tab reads the record. This module owns the taxonomy, the
# weights and the case derivation; every word a learner reads is in
# `lesson.proctor.*` in the locale files.
module Proctoring
  # What each kind of incident costs the integrity score.
  WEIGHTS = {
    menu: 2, paste_small: 3, copy: 5, blur: 8, print: 10, paste: 15, capture: 20
  }.freeze

  # A paste longer than this reads as pasted-in work rather than a typo fix, and
  # is weighted as `paste` instead of `paste_small`.
  PASTE_LIMIT = 120

  # Where the score sits, best band first. `band_for` takes the first floor the
  # score clears, so the order matters more than the numbers.
  BANDS = { clean: 85, review: 60, risk: 0 }.freeze

  START_SCORE = 100

  # The log keeps only the most recent few — it is a sidebar, not a report.
  MAX_EVENTS = 6

  # A learner's unreviewed events, scored. Derived, never stored — like every
  # status in this app, so closing a case cannot disagree with the events that
  # opened it. The pill maps the score's band onto the severity copy.
  Case = Data.define(:user, :score, :events) do
    def band = Proctoring.band_for(score)
    def severity = { risk: :high, review: :medium, clean: :low }.fetch(band)
    def severity_name = I18n.t("admin.integrity.severity.#{severity}")

    # Where the latest incident happened — course and module, which is as
    # precise as the screen needs to be.
    def where_text
      event = events.first
      I18n.t("admin.integrity.where", course: event.course.code, module: event.topic.module_number)
    end
  end

  class << self
    def band_for(score) = BANDS.find { |_, floor| score >= floor }.first

    # Weights and copy travel to the browser together so the controller never
    # has to know an event kind the locale file has no sentence for.
    def event_copy
      WEIGHTS.map { |kind, weight| { kind:, weight:, text: I18n.t("lesson.proctor.events.#{kind}") } }
    end

    # ---- The admin Integrity tab -------------------------------------------
    # Reads records, like AdminConsole.head_stats and for the same reason: the
    # events are real now, and a tab of sample cases above a real roster would
    # be the worst kind of plausible. Worst score first.

    def cases
      ProctorEvent.unreviewed.newest_first.includes(:user, :course, :topic)
                  .group_by(&:user)
                  .map { |user, events| Case.new(user:, score: score_for(events), events:) }
                  .sort_by(&:score)
    end

    def score_for(events) = [ START_SCORE - events.sum(&:weight), 0 ].max

    def open_case_count = ProctorEvent.unreviewed.distinct.count(:user_id)
  end
end
