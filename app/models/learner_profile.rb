# What is still placeholder about a learner. The list has shrunk twice: the
# counting moved to LearnerProgress when topic_completions landed, and the award
# shelf followed once submissions gave its rules something to check. What is
# left is exactly what nothing records yet:
#
#   hearts — no wrong answer costs a life, and nothing refills one
#
# Notifications left for their own table once enrolments and integrity
# decisions gave them something to say. When hearts follow (or are dropped),
# this module is two constants and a tab whitelist, and can go.
module LearnerProfile
  LIVES = 5
  MAX_LIVES = 5

  # The two My Learning tabs. Both lists render on every visit — the tab is a
  # show/hide in the browser, not a round trip.
  TABS = %i[ progress done ].freeze

  class << self
    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : TABS.first
    end
  end
end
