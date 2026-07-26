# Everything the app knows about one learner's progress, counted off
# topic_completions. This is the first screen-facing object backed by real
# records rather than by a frozen constant — LearnerProfile keeps only the parts
# that still have nothing recording them (hearts, awards, notifications).
#
# The rules that turn completions into figures live here rather than in the
# table: XP and gems per topic, how long a level is, what counts as a streak day.
# They are display conventions, and moving them means a migration if they are
# columns and a redeploy if they are not.
#
# A learner's rows are loaded once and folded in Ruby rather than aggregated in
# SQL. The volume is one row per topic per student, the date arithmetic wants
# Time.zone rather than SQLite's, and the screens ask for six different cuts of
# the same rows.
class LearnerProgress
  XP_PER_LEARNED = 120
  XP_PER_APPLIED = 60
  # The lesson's two graded steps hand out these, and the sidebar counter adds
  # them up client-side — keep them in step with the `gems` values in the
  # `quiz` and `code_task` Stimulus controllers.
  GEMS_PER_LEARNED = 5
  GEMS_PER_APPLIED = 10

  XP_PER_LEVEL = 400

  # 12 weeks of squares, 28 to a row — the contribution grid on /progress.
  ACTIVITY_DAYS = 84
  ACTIVITY_COLUMNS = 28
  # Heat 0 is an empty day; a day with this many completions is as hot as the
  # grid goes.
  HOTTEST = 4

  attr_reader :user

  def initialize(user)
    @user = user
  end

  # ---- Raw material -------------------------------------------------------

  # `course_code` and `topic_key` are readers on the association now that the
  # taxonomy is a table, so the course and topic come along for the ride — three
  # queries whatever the row count, rather than two per row.
  def completions
    @completions ||= user ? user.topic_completions.includes(:course, :topic).to_a : []
  end

  def any? = completions.any?

  # code => [learned, applied]
  def course_counts
    @course_counts ||= completions.group_by(&:course_code).transform_values do |rows|
      [ rows.size, rows.count(&:applied?) ]
    end
  end

  def keys_for(code) = completions.select { it.course_code == code }.map(&:topic_key).to_set

  # ---- Courses ------------------------------------------------------------

  # The catalog with this learner's counts filled in. One pass over the rows
  # feeds every card, so the catalog is still a single query.
  def courses
    @courses ||= CourseCatalog.all.map do |course|
      learned, applied = course_counts.fetch(course.code, [ 0, 0 ])
      course.with(learned:, applied:, next_key: Syllabus.next_topic_key(keys_for(course.code)))
    end
  end

  def started_courses = courses.select(&:started?)

  # My Learning's two tabs. A course leaves "in progress" only by being finished.
  def courses_for(tab)
    tab.to_s == "done" ? started_courses.select(&:completed?) : started_courses.reject(&:completed?)
  end

  # ---- Totals -------------------------------------------------------------
  # Counted across the courses actually started: a total that included the whole
  # catalogue would make every learner look permanently stalled.

  def learned = completions.size
  def applied = completions.count(&:applied?)
  def learned_total = started_courses.sum(&:topics)
  def applied_total = started_courses.sum(&:applied_topics)

  def learned_percent = percent(learned, learned_total)
  def applied_percent = percent(applied, applied_total)

  # Wall-clock time is not recorded; the minutes budgeted for each finished topic
  # in the syllabus are the closest honest estimate.
  def minutes_studied = completions.sum { Syllabus.topic_minutes(it.topic_key) }
  def hours_studied = (minutes_studied / 60.0).round(1)

  # ---- XP, level and gems -------------------------------------------------

  def xp = learned * XP_PER_LEARNED + applied * XP_PER_APPLIED
  def gems = learned * GEMS_PER_LEARNED + applied * GEMS_PER_APPLIED

  def level = xp / XP_PER_LEVEL + 1
  def level_floor = (level - 1) * XP_PER_LEVEL
  def xp_target = level * XP_PER_LEVEL
  def xp_percent = percent(xp - level_floor, XP_PER_LEVEL)
  def xp_to_next = xp_target - xp

  # ---- Days ---------------------------------------------------------------

  def active_dates = @active_dates ||= completions.flat_map(&:active_days).to_set

  # Consecutive days up to today. Yesterday still counts as the head of the run,
  # so a streak is not reported as broken until a whole day has been missed.
  def streak
    head = [ Date.current, Date.current - 1 ].find { active_dates.include?(it) }
    return 0 unless head

    day = head
    day -= 1 while active_dates.include?(day - 1)
    (head - day).to_i + 1
  end

  def learned_this_week = completions.count { it.learned_at.in_time_zone >= Date.current.beginning_of_week }

  def hours_this_week
    minutes = completions.sum do
      it.learned_at.in_time_zone >= Date.current.beginning_of_week ? Syllabus.topic_minutes(it.topic_key) : 0
    end
    (minutes / 60.0).round(1)
  end

  # 12 weeks of heat levels, oldest first — index 0 is 83 days ago, the last is
  # today, so the grid always ends on the square a learner is filling now.
  def activity
    counts = Hash.new(0)
    completions.each { |completion| completion.active_days.each { counts[it] += 1 } }

    first = Date.current - (ACTIVITY_DAYS - 1)
    Array.new(ACTIVITY_DAYS) { [ counts[first + it], HOTTEST ].min }
  end

  # ---- Standing -----------------------------------------------------------

  # Rank among students by XP, ties broken by who got there first. Nil until the
  # learner has recorded anything — an unranked row reads better than a last
  # place nobody competed for.
  def rank
    return nil unless any?

    self.class.standings.index { it.first == user.id }&.+(1)
  end

  # The dashboard's four tiles. Three are counted; "projects submitted" is not —
  # nothing records a project yet, so its value and its delta stay copy, and the
  # locale file is where that shows.
  def dashboard_stats
    copy = I18n.t("progress.stats")

    [
      copy[0].merge(value: learned.to_s, delta: delta("topics", learned_this_week)),
      copy[1].merge(value: hours_studied.to_s, delta: delta("hours", hours_this_week)),
      copy[2],
      copy[3].merge(value: rank ? "##{rank}" : "—")
    ]
  end

  class << self
    # [[user_id, xp], …] best first. Two grouped counts rather than one SQL
    # expression, so the XP rule stays in Ruby where the rest of it lives.
    def standings
      learned = TopicCompletion.group(:user_id).count
      applied = TopicCompletion.applied.group(:user_id).count

      learned.map { |id, count| [ id, count * XP_PER_LEARNED + applied.fetch(id, 0) * XP_PER_APPLIED ] }
             .sort_by { |id, xp| [ -xp, id ] }
    end
  end

  private
    def percent(part, whole) = whole.to_i.zero? ? 0 : (part * 100.0 / whole).round

    # "+0 this week" reads as a broken counter rather than as a quiet week.
    def delta(kind, count)
      count.zero? ? I18n.t("progress.delta.none") : I18n.t("progress.delta.#{kind}", count:)
    end
end
