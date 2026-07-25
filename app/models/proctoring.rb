# Academic-integrity monitoring for the lesson screen.
#
# Everything here runs in the browser (see the `proctor` Stimulus controller) and
# nothing is persisted: reload the lesson and the score is 100 again. That is the
# same bargain the exercise and coding task already make — the design's feedback
# survives, the enforcement does not. Real proctoring needs the events posted to
# the server and written to an instructor report.
#
# This module holds the taxonomy and the numbers; every word a learner reads is
# in `lesson.proctor.*` in the locale files.
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

  class << self
    def band_for(score) = BANDS.find { |_, floor| score >= floor }.first

    # Weights and copy travel to the browser together so the controller never
    # has to know an event kind the locale file has no sentence for.
    def event_copy
      WEIGHTS.map { |kind, weight| { kind:, weight:, text: I18n.t("lesson.proctor.events.#{kind}") } }
    end
  end
end
