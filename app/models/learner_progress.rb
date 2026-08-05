# Everything the app knows about one learner's progress, counted off topic
# completions, prior-knowledge marks, and submissions. It was the first screen-facing object
# backed by real records rather than a frozen constant, and it absorbed the
# rest of LearnerProfile piece by piece until that module could go.
#
# The rules that turn completions into figures live here rather than in the
# table: XP and gems per topic, how long a level is, what counts as a streak day.
# They are display conventions, and moving them means a migration if they are
# columns and a redeploy if they are not.
#
# A learner's rows are loaded once and folded in Ruby rather than aggregated in
# SQL. The volume is one row per topic per student, the date arithmetic wants
# Time.zone rather than the database's, and the screens ask for six different
# cuts of the same rows.
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

  def prior_knowledges
    @prior_knowledges ||= user ? user.prior_knowledges.includes(:course, :topic).to_a : []
  end

  def any? = completions.any?

  # code => [learned, applied]
  def course_counts
    @course_counts ||= begin
      completion_groups = completions.group_by(&:course_code)
      known_groups = prior_knowledges.group_by(&:course_code)
      (completion_groups.keys | known_groups.keys).index_with do |code|
        completion_rows = completion_groups.fetch(code, [])
        known_keys = known_groups.fetch(code, []).map(&:topic_key)
        [ (completion_rows.map(&:topic_key) | known_keys).size, completion_rows.count(&:applied?) ]
      end
    end
  end

  def keys_for(code) = completions.select { it.course_code == code }.map(&:topic_key).to_set
  def prior_knowledge_keys_for(code) = prior_knowledges.select { it.course_code == code }.map(&:topic_key).to_set
  def map_keys_for(code) = keys_for(code) | prior_knowledge_keys_for(code)

  # ---- Courses ------------------------------------------------------------

  # The catalog with this learner's counts filled in. One pass over the rows
  # feeds every card, so the catalog is still a single query.
  def courses
    @courses ||= CourseCatalog.all(user:).map do |course|
      learned, applied = course_counts.fetch(course.code, [ 0, 0 ])
      academy_learned = completions.count { it.course_code == course.code }
      course.with(learned:, applied:, academy_learned:,
                  next_key: Syllabus.next_topic_key(keys_for(course.code), course.code))
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

  def learned = course_counts.values.sum(&:first)
  def applied = completions.count(&:applied?)
  def learned_total = started_courses.sum(&:topics)
  def applied_total = started_courses.sum(&:applied_topics)

  def learned_percent = percent(learned, learned_total)
  def applied_percent = percent(applied, applied_total)

  # Wall-clock time is not recorded; the minutes budgeted for each finished topic
  # in the syllabus are the closest honest estimate.
  def minutes_studied = completions.sum { Syllabus.topic_minutes(it.topic_key, it.course_code) }
  def hours_studied = (minutes_studied / 60.0).round(1)

  # ---- XP, level and gems -------------------------------------------------

  def xp = completions.size * XP_PER_LEARNED + applied * XP_PER_APPLIED
  def gems = completions.size * GEMS_PER_LEARNED + applied * GEMS_PER_APPLIED

  def level = xp / XP_PER_LEVEL + 1
  def level_floor = (level - 1) * XP_PER_LEVEL
  def xp_target = level * XP_PER_LEVEL
  def xp_percent = percent(xp - level_floor, XP_PER_LEVEL)
  def xp_to_next = xp_target - xp

  # ---- Days ---------------------------------------------------------------

  def active_dates = @active_dates ||= completions.flat_map(&:active_days).to_set

  # Consecutive days up to today. Yesterday still counts as the head of the run,
  # so a streak is not reported as broken until a whole day has been missed.
  def streak = self.class.streak_from(active_dates)

  # The one streak rule, callable without a LearnerProgress: the leaderboard
  # scores a whole section from one query and cannot afford an instance (and its
  # query) per row.
  def self.streak_from(dates, today: Date.current)
    head = [ today, today - 1 ].find { dates.include?(it) }
    return 0 unless head

    day = head
    day -= 1 while dates.include?(day - 1)
    (head - day).to_i + 1
  end

  def learned_this_week = completions.count { it.learned_at.in_time_zone >= Date.current.beginning_of_week }

  def hours_this_week
    minutes = completions.sum do
      it.learned_at.in_time_zone >= Date.current.beginning_of_week ? Syllabus.topic_minutes(it.topic_key, it.course_code) : 0
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

  # ---- Projects and certificates ------------------------------------------
  # A project is a syllabus topic of kind "project", and submitting one is
  # applying it. Certificates follow the courses that carry the flag.

  def projects_done = completions.count { it.applied? && project_keys(it.course_code).include?(it.topic_key) }
  def projects_total = started_courses.sum { project_keys(it.code).size }

  def certificates_earned = courses.count { it.certificate && it.academy_completed? }
  def certificates_total = courses.count(&:certificate)

  # ---- Hearts -------------------------------------------------------------
  # The counter is honest, not punitive: a failed attempt costs a heart for
  # HEART_WINDOW and then it grows back, and NOTHING blocks at zero — whether an
  # empty set of hearts should gate anything is a pedagogy decision nobody has
  # made, and this display does not sneak it in. It replaces a constant 5/5
  # beside a hardcoded refill timer, which was the counter as pure theatre.

  HEARTS = 5
  HEART_WINDOW = 4.hours

  def hearts = [ HEARTS - recent_failures.size, 0 ].max
  def hearts_max = HEARTS

  # When the next heart grows back — the oldest counted failure ages out first.
  # Nil at full.
  def heart_refill_at
    return nil if recent_failures.empty?

    recent_failures.min_by(&:created_at).created_at + HEART_WINDOW
  end

  # ---- Awards -------------------------------------------------------------
  # Derived, never stored — the same trick as Syllabus locking: each award is a
  # rule over the rows this class already holds, so earning one cannot drift
  # from the work that earned it. Position joins `my_learning.awards`, which
  # still owns every word.
  #
  # `forum_helper?` is the one rule with nothing to count: no forum records an
  # answer, so the award stays honestly unearnable until one does.

  AWARDS = [
    { glyph: "◆", rule: :ten_topics? },
    { glyph: "▲", rule: :first_project? },
    { glyph: "✦", rule: :week_streak? },
    { glyph: "❖", rule: :every_exercise? },
    { glyph: "◈", rule: :module_in_a_day? },
    { glyph: "✚", rule: :forum_helper? },
    { glyph: "♦", rule: :passed_after_fails? },
    { glyph: "☗", rule: :final_module? }
  ].freeze

  # The dashboard's smaller shelf shows the first six of the same awards — one
  # list, two crops, so the two screens cannot disagree about what is earned.
  DASHBOARD_BADGE_COUNT = 6

  # "Persistent" asks for this many wrong answers before the pass.
  PERSISTENT_FAILS = 3

  def awards
    @awards ||= I18n.t("my_learning.awards").each_with_index.map do |copy, index|
      award = AWARDS[index]
      { name: copy[:name], hint: copy[:hint], glyph: award[:glyph], earned: send(award[:rule]) }
    end
  end

  def dashboard_badges = awards.first(DASHBOARD_BADGE_COUNT)
  def awards_earned = awards.count { it[:earned] }
  def awards_total = AWARDS.size

  # ---- Standing -----------------------------------------------------------

  # Rank among students by XP, ties broken by who got there first. Nil until the
  # learner has recorded anything — an unranked row reads better than a last
  # place nobody competed for.
  def rank
    return nil unless any?

    self.class.standings.index { it.first == user.id }&.+(1)
  end

  # The dashboard's four tiles, every value counted. The projects tile's delta
  # stays copy: it states where the number comes from, because nothing stores a
  # deadline to count down to.
  def dashboard_stats
    copy = I18n.t("progress.stats")

    [
      copy[0].merge(value: learned.to_s, delta: delta("topics", learned_this_week)),
      copy[1].merge(value: hours_studied.to_s, delta: delta("hours", hours_this_week)),
      copy[2].merge(value: "#{projects_done} / #{projects_total}"),
      copy[3].merge(value: rank ? "##{rank}" : "—")
    ]
  end

  class << self
    # [[user_id, xp], …] best first. Two grouped counts rather than one SQL
    # expression, so the XP rule stays in Ruby where the rest of it lives.
    #
    # Both counts read the *whole* table, which is what makes this the app's
    # known hotspot — so it is held on Current for the length of the request.
    # /progress asks for a rank more than once and used to pay for all of it
    # twice. This is the first thing to cache or denormalise when a few thousand
    # rows becomes more; memoising per request is what buys the time to.
    def standings
      Current.standings ||= begin
        learned = TopicCompletion.group(:user_id).count
        applied = TopicCompletion.applied.group(:user_id).count

        learned.map { |id, count| [ id, count * XP_PER_LEARNED + applied.fetch(id, 0) * XP_PER_APPLIED ] }
               .sort_by { |id, xp| [ -xp, id ] }
      end
    end

    # Anything that writes a completion has changed the ranking — the same
    # contract LandingText.forget and Landing.forget_cards carry.
    def forget_standings = Current.standings = nil
  end

  private
    def percent(part, whole) = whole.to_i.zero? ? 0 : (part * 100.0 / whole).round

    # ---- The award rules --------------------------------------------------

    def project_keys(course_code)
      @project_keys ||= {}
      @project_keys[course_code] ||= Syllabus.topics(course_code).select { it.kind == "project" }.map(&:key).to_set
    end

    def exercise_keys(course_code)
      @exercise_keys ||= {}
      @exercise_keys[course_code] ||= Syllabus.topics(course_code).select { it.kind == "exercise" }.map(&:key)
    end

    def ten_topics? = completions.size >= 10

    def first_project? = projects_done.positive?

    # The longest run ever, not the current streak — a streak once run stays
    # earned even after it breaks.
    def week_streak?
      dates = active_dates.sort
      return false if dates.empty?

      longest = run = 1
      dates.each_cons(2) do |a, b|
        run = b == a + 1 ? run + 1 : 1
        longest = [ longest, run ].max
      end
      longest >= 7
    end

    def every_exercise?
      started_courses.any? { |course| exercise_keys(course.code).all? { keys_for(course.code).include?(it) } }
    end

    # Every topic of one module learned on the same day, in any course.
    def module_in_a_day?
      started_courses.any? do |course|
        by_key = completions.select { it.course_code == course.code }.index_by(&:topic_key)

        Syllabus.entries(course.code).map(&:number).any? do |number|
          keys = Syllabus.keys_in(number, course.code)
          keys.all? { by_key[it] } &&
            keys.map { by_key[it].learned_at.in_time_zone.to_date }.uniq.one?
        end
      end
    end

    # No forum records an answer yet; see the note above AWARDS.
    def forum_helper? = false

    # A pass that took persistence: the same task failed PERSISTENT_FAILS times
    # before the submission that made it. Counted off submissions, which is why
    # the failures are kept.
    def passed_after_fails?
      own_submissions.group_by { [ it.topic_id, it.kind ] }.any? do |_task, tries|
        first_pass = tries.index(&:passed?)
        first_pass && first_pass >= PERSISTENT_FAILS
      end
    end

    def final_module?
      started_courses.any? do |course|
        last = Syllabus.entries(course.code).map(&:number).max
        Syllabus.keys_in(last, course.code).all? { keys_for(course.code).include?(it) }
      end
    end

    def recent_failures
      @recent_failures ||= own_submissions.select { !it.passed? && it.created_at > HEART_WINDOW.ago }
    end

    def own_submissions
      @own_submissions ||= user ? user.submissions.order(:created_at, :id).to_a : []
    end

    # "+0 this week" reads as a broken counter rather than as a quiet week.
    def delta(kind, count)
      count.zero? ? I18n.t("progress.delta.none") : I18n.t("progress.delta.#{kind}", count:)
    end
end
