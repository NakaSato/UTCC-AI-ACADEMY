# What is still placeholder about a learner once LearnerProgress took over the
# counting: hearts, the award shelf, the badge row and the notification list.
#
# Each of these is waiting for something to record it — a wrong answer costing a
# life, a rule saying which award a run of completions earns, a notification
# worth sending. Until then they are the same frozen constants the rest of
# app/models/ holds, and the same rule applies: numbers and shape here, every
# word a human reads in config/locales.
module LearnerProfile
  LIVES = 5
  MAX_LIVES = 5

  # The two My Learning tabs. Both lists render on every visit — the tab is a
  # show/hide in the browser, not a round trip.
  TABS = %i[ progress done ].freeze

  # glyph, earned?, tier — index matches `my_learning.awards` in the locales.
  AWARDS = [
    [ "◆", true,  2 ],
    [ "▲", true,  1 ],
    [ "✦", true,  4 ],
    [ "❖", true,  1 ],
    [ "◈", false, nil ],
    [ "✚", false, nil ],
    [ "♦", false, nil ],
    [ "☗", true,  1 ]
  ].freeze

  # The smaller badge row on the dashboard: name, earned?, glyph.
  DASHBOARD_BADGES = [
    [ "First Model",   true,  "▲" ],
    [ "7-Day Streak",  true,  "✦" ],
    [ "Data Cleaner",  true,  "❖" ],
    [ "Model Builder", false, "◈" ],
    [ "Deep Diver",    false, "◆" ],
    [ "Ethics Aware",  false, "☗" ]
  ].freeze

  class << self
    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : TABS.first
    end

    def awards
      copy = I18n.t("my_learning.awards")

      AWARDS.each_with_index.map do |(glyph, earned, tier), index|
        { name: copy[index][:name], hint: copy[index][:hint], glyph:, earned:, tier: }
      end
    end

    def dashboard_badges
      DASHBOARD_BADGES.map { |name, earned, glyph| { name:, earned:, glyph: } }
    end

    def notifications
      # The first two are unread, matching the design's dot and tinted row.
      I18n.t("chrome.notifications").each_with_index.map do |copy, index|
        copy.merge(unread: index < 2)
      end
    end
  end
end
