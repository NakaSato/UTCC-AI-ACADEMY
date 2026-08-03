# The leaderboard, ranked off the same rows every other figure is counted from.
# It was eight frozen rows and a name array in the locale files, because there
# was no section to rank within; now there is, so the figures come from
# topic_completions and the XP rule stays in LearnerProgress where it lives.
#
# The three tabs are two questions — who am I ranked against, and since when:
#
#   week        the viewer's section, XP earned since Monday
#   semester    the viewer's section, all time (one term of data: the whole
#               table IS the semester, so no date cut is pretended)
#   university  every student, all time
#
# A viewer in no section is ranked against everyone on every tab — a board of
# one would be the alternative, and it ranks nobody against nothing.
class Leaderboard
  TABS = %i[ week semester university ].freeze

  PODIUM = 3

  Entry = Data.define(:rank, :user, :xp, :topics, :streak, :section_code, :you) do
    def you? = you
    def podium? = rank <= PODIUM
    def name = user.name
    def initials = user.initials
    def section_text = section_code ? I18n.t("units.section", name: section_code) : ""
    def streak_text = I18n.t("units.days", count: streak)
  end

  attr_reader :viewer, :tab, :course

  def initialize(viewer, tab, course_code: Syllabus::DEFAULT_COURSE)
    @viewer = viewer
    @tab = tab
    @course = Course.find_by(code: course_code) || Course.find_by!(code: Syllabus::DEFAULT_COURSE)
  end

  # The viewer's home section — what the subtitle names, whatever the tab.
  def section = @section ||= viewer&.sections&.find_by(course:)

  # Ranked best-first, ties broken by id so equal scores keep a stable order.
  # Only learners with XP inside the window appear: an all-zero row is not a
  # rank, which is also why LearnerProgress#rank answers nil for a new account.
  def entries
    @entries ||= scores.each_with_index.map do |row, index|
      Entry.new(rank: index + 1, user: users_by_id.fetch(row[:user_id]),
                xp: ActiveSupport::NumberHelper.number_to_delimited(row[:xp]),
                topics: row[:topics], streak: row[:streak],
                section_code: section_codes[row[:user_id]],
                you: row[:user_id] == viewer&.id)
    end
  end

  class << self
    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : TABS.first
    end

    def tab_labels = TABS.zip(I18n.t("leaderboard.tabs")).to_h
  end

  private
    def week? = tab == :week
    def university? = tab == :university

    # Nil means no cut. Streaks ignore it on purpose — a run of days is a fact
    # about the learner, not about the range being looked at.
    def window = week? ? Date.current.beginning_of_week : nil

    def in_window?(stamp) = window.nil? || stamp.in_time_zone.to_date >= window

    def contenders
      @contenders ||= (university? || section.nil? ? User.student : section.students).to_a
    end

    def users_by_id = @users_by_id ||= contenders.index_by(&:id)

    # One query for the whole board, folded per learner in Ruby — the same shape
    # LearnerProgress takes for one learner, and the reason Entry rows cost no
    # queries of their own.
    def completions
      @completions ||= TopicCompletion.where(user: contenders, course:).to_a.group_by(&:user_id)
    end

    def scores
      completions.filter_map { |user_id, rows| score(user_id, rows) }
                 .sort_by { [ -it[:xp], it[:user_id] ] }
    end

    def score(user_id, rows)
      learned = rows.count { in_window?(it.learned_at) }
      applied = rows.count { it.applied? && in_window?(it.applied_at) }
      return nil if learned.zero? && applied.zero?

      { user_id:, topics: learned,
        xp: learned * LearnerProgress::XP_PER_LEARNED + applied * LearnerProgress::XP_PER_APPLIED,
        streak: LearnerProgress.streak_from(rows.flat_map(&:active_days).to_set) }
    end

    # user_id => the code of a section they are enrolled in, for the row's
    # second line. One query; a learner in several sections shows the first.
    def section_codes
      @section_codes ||= Enrollment.joins(:section)
                                   .where(user_id: users_by_id.keys, sections: { course_id: course.id })
                                   .order(:id)
                                   .pluck(:user_id, "sections.code")
                                   .reverse.to_h
    end
end
