# The signed-in learner's placeholder state: streak, badges, enrolments
# and the contribution grid. Real per-user records replace this wholesale.
module LearnerProfile
  STREAK = 12
  LIVES = 5
  MAX_LIVES = 5

  # Dashboard headline figures — labels and deltas live in the locale files.
  STAT_VALUES = [ "41", "28.5", "5 / 9", "#4" ].freeze

  XP_LEVEL = 7
  XP_CURRENT = 2_480
  XP_TARGET = 3_000

  Enrolment = Data.define(:code, :percent) do
    def title = I18n.t("progress.enrolled_short.#{code}", default: I18n.t("catalog.courses.#{code}.title"))
    def next_up = I18n.t("progress.enrolled.#{code}")
  end

  ENROLMENTS = [
    { code: "AI1101", percent: 32 },
    { code: "AI1102", percent: 60 },
    { code: "AI2105", percent: 40 }
  ].freeze

  # code, state, learned/total topics, applied/total topics
  Enrollment = Data.define(:code, :state, :learned, :learned_total, :applied, :applied_total) do
    def title = I18n.t("catalog.courses.#{code}.title")
    def description = I18n.t("catalog.courses.#{code}.desc")
    def badge = I18n.t("my_learning.badge_state.#{state}")
    def in_progress? = state == :now
    def learned_text = I18n.t("my_learning.learned_count", done: learned, total: learned_total)
    def applied_text = I18n.t("my_learning.applied_count", done: applied, total: applied_total)
    def learned_percent = (learned * 100.0 / learned_total).round
    def applied_percent = (applied * 100.0 / applied_total).round
  end

  # The two My Learning tabs. Both lists render on every visit — the tab is a
  # show/hide in the browser, not a round trip.
  TABS = %i[ progress done ].freeze

  IN_PROGRESS = [
    { code: "AI1101", state: :now, learned: 24, learned_total: 75, applied: 8,  applied_total: 62 },
    { code: "AI1102", state: :now, learned: 41, learned_total: 68, applied: 22, applied_total: 50 },
    { code: "AI2105", state: :now, learned: 12, learned_total: 30, applied: 5,  applied_total: 24 }
  ].freeze

  COMPLETED = [
    { code: "AI2402", state: :done, learned: 22, learned_total: 22, applied: 14, applied_total: 14 }
  ].freeze

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

  # Overall figures on the My Learning header card.
  LEARNED_TOPICS = 24
  LEARNED_TOTAL = 75
  APPLIED_TOPICS = 8
  APPLIED_TOTAL = 62

  ACTIVITY_DAYS = 84
  ACTIVITY_COLUMNS = 28

  class << self
    def enrolments = ENROLMENTS.map { |attrs| Enrolment.new(**attrs) }

    def enrollments(tab)
      (tab.to_s == "done" ? COMPLETED : IN_PROGRESS).map { |attrs| Enrollment.new(**attrs) }
    end

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

    def dashboard_stats
      I18n.t("progress.stats").each_with_index.map do |copy, index|
        copy.merge(value: STAT_VALUES[index])
      end
    end

    def notifications
      # The first two are unread, matching the design's dot and tinted row.
      I18n.t("chrome.notifications").each_with_index.map do |copy, index|
        copy.merge(unread: index < 2)
      end
    end

    def xp_percent = (XP_CURRENT * 100.0 / XP_TARGET).round

    def learned_percent = (LEARNED_TOPICS * 100.0 / LEARNED_TOTAL).round
    def applied_percent = (APPLIED_TOPICS * 100.0 / APPLIED_TOTAL).round

    # A deterministic 12-week contribution grid: level 0 (coldest) to 4.
    # The last week is always hot so the streak claim in the copy holds up.
    def activity
      Array.new(ACTIVITY_DAYS) do |day|
        next 4 if day > 78

        seed = (day * 37 + 11) % 100
        case seed
        when ...26 then 0
        when ...48 then 1
        when ...70 then 2
        when ...88 then 3
        else            4
        end
      end
    end
  end
end
