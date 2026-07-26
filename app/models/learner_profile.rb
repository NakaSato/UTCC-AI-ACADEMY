# What is still placeholder about a learner. The list has shrunk twice: the
# counting moved to LearnerProgress when topic_completions landed, and the award
# shelf followed once submissions gave its rules something to check. What is
# left is exactly what nothing records yet:
#
#   hearts        — no wrong answer costs a life, and nothing refills one
#   notifications — no deadline, grade or approval exists to notify about
#
# When either gets a table, its copy moves out of here the same way the awards'
# rules did — and this module gets smaller again, which is the point.
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

    def notifications
      # The first two are unread, matching the design's dot and tinted row.
      I18n.t("chrome.notifications").each_with_index.map do |copy, index|
        copy.merge(unread: index < 2)
      end
    end
  end
end
