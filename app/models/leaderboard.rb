# The section leaderboard. Names live in `leaderboard.leaders`; the figures and
# the row that is "you" live here.
module Leaderboard
  TABS = %i[ week semester university ].freeze

  # Row 4 is the signed-in learner, which the design highlights.
  YOU_INDEX = 3

  Entry = Data.define(:rank, :name, :section, :xp, :topics, :streak) do
    def you? = rank == YOU_INDEX + 1
    def podium? = rank <= 3
    def section_text = I18n.t("units.section", name: section)
    def streak_text = I18n.t("units.days", count: streak)
    def initials = name.first(2)
  end

  # section, xp, topics, streak — in rank order.
  FIGURES = [
    [ "BA-2", "4,120", 68, 41 ],
    [ "BA-1", "3,905", 64, 33 ],
    [ "BA-2", "3,610", 59, 28 ],
    [ "BA-2", "2,480", 41, 12 ],
    [ "BA-3", "2,310", 38,  9 ],
    [ "BA-1", "2,140", 35, 17 ],
    [ "BA-2", "1,980", 31,  6 ],
    [ "BA-3", "1,760", 28,  4 ]
  ].freeze

  class << self
    def entries
      names = I18n.t("leaderboard.leaders")

      FIGURES.each_with_index.map do |(section, xp, topics, streak), index|
        Entry.new(rank: index + 1, name: names[index], section:, xp:, topics:, streak:)
      end
    end

    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : TABS.first
    end

    def tab_labels = TABS.zip(I18n.t("leaderboard.tabs")).to_h
  end
end
