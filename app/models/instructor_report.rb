# The instructor view of a section: cohort figures, the topics students fail
# most often on first attempt, and the roster.
#
# It was a module of frozen figures because there was no section to report on and
# no record of an attempt to count. Both exist now, so this is an ordinary class
# over `sections`, `enrollments`, `topic_completions` and `submissions` — the
# same shape LearnerProgress takes, and it keeps every reader name the view
# already called.
#
# Nothing on this screen is invented any more. The last figure that was —
# "average exercise score" — is counted now that `submissions.score` exists: the
# coding task's criteria were always graded one at a time, and the share of them
# that matched is what the tile is a mean of.
class InstructorReport
  # A student is on track at 50% of the syllabus, behind under 25%.
  ON_TRACK = 50
  BEHIND = 25

  # Above this share of first attempts failing, a topic reads as a problem rather
  # than as a warning.
  ALARM_THRESHOLD = 50
  WARN_THRESHOLD = 40

  # How many of the hardest topics the panel lists.
  HARD_TOPIC_LIMIT = 5

  # The tile reads out of ten, while a score is stored out of a hundred.
  SCORE_DIVISOR = 10

  # A learner is "inactive" once this many days have passed with nothing recorded.
  INACTIVE_AFTER = 7

  attr_reader :section

  def initialize(section)
    @section = section
  end

  # ---- Roster ---------------------------------------------------------------

  Student = Data.define(:user, :percent, :projects, :projects_total, :seen) do
    def id = user.student_id
    def name = user.name
    def on_track? = percent >= ON_TRACK
    def behind? = percent < BEHIND
    def projects_text = "#{projects} / #{projects_total}"

    def seen_text
      case seen
      in nil then I18n.t("instructor.seen.never")
      in 0 then I18n.t("instructor.seen.today")
      in 1 then I18n.t("instructor.seen.yesterday")
      else      I18n.t("instructor.seen.days_ago", count: seen)
      end
    end
  end

  # Ordered by progress, furthest along first — the design's order, and the one
  # that puts the students worth following up at the bottom where they are easy
  # to find.
  def roster
    @roster ||= students.map { student_row(it) }.sort_by { [ -it.percent, it.name ] }
  end

  # ---- Cohort figures -------------------------------------------------------

  def size = students.size

  def average_percent = roster.any? ? (roster.sum(&:percent) / roster.size.to_f).round : 0

  # On time means the project topics that are done, over the ones that exist,
  # across the whole section — the closest honest reading of "submissions in" for
  # a course with no deadlines in it yet.
  def on_time_percent
    total = roster.sum(&:projects_total)
    total.zero? ? 0 : (roster.sum(&:projects) * 100.0 / total).round
  end

  def inactive_count = roster.count { it.seen.nil? || it.seen > INACTIVE_AFTER }

  # Each learner's best attempt at each graded step, averaged over the section.
  # Best rather than first, for two reasons: a gradebook reports what a student
  # achieved rather than what they first guessed, and first attempts are what the
  # hard-topics panel below is already about — counting them here too would make
  # the screen say one thing twice.
  #
  # Rows with no score predate the column and do not vote; a section with nothing
  # scored reports 0, the way the other three tiles do when they have nothing.
  def average_score
    best = scored_attempts.values.map(&:max)

    best.any? ? (best.sum / best.size.to_f / SCORE_DIVISOR).round(1) : 0
  end

  def projects_done = roster.sum(&:projects)
  def projects_total = roster.sum(&:projects_total)

  # The on-time tile's note is counted rather than written: it used to read
  # "39 of 48 students" beside whatever the value was, which is the kind of
  # caption that goes on looking authoritative long after it stops being true.
  def stats
    copy = I18n.t("instructor.stats").each_with_index.map { |row, index| row.merge(value: stat_values[index]) }

    copy[1] = copy[1].merge(note: I18n.t("instructor.on_time_note", done: projects_done, total: projects_total))
    copy
  end

  # ---- Export ---------------------------------------------------------------

  # The roster as CSV: the same columns the screen shows, headed by the same
  # locale strings, so the file reads in whichever language the console was in.
  # Hand-rolled rather than require "csv" — Ruby 3.4 moved that to a bundled
  # gem Bundler does not load, and six quoted columns do not earn a dependency.
  # The BOM is for Excel, which otherwise guesses Thai names into mojibake.
  def grades_csv
    headers = %w[ th_id th_name th_progress th_projects th_seen ].map { I18n.t("instructor.#{it}") }
    rows = roster.map { [ it.id, it.name, "#{it.percent}%", it.projects_text, it.seen_text ] }

    "\uFEFF" + ([ headers ] + rows).map { |row| row.map { csv_field(it) }.join(",") }.join("\n")
  end

  # "grades-AI1101-BA-2-1-2569.csv" — the term's slash would otherwise nest the
  # filename into a directory.
  def grades_filename
    [ "grades", section.course.code, section.code, section.term.tr("/", "-") ].join("-") + ".csv"
  end

  # ---- The topics students get wrong ----------------------------------------

  # Share of learners whose **first** attempt at a topic failed. Counted off
  # submissions, which is the whole reason failures are kept: a topic everybody
  # eventually passes can still be the one everybody gets wrong first.
  def hard_topics
    first_attempts
      .map { |topic, attempts| hard_topic_row(topic, attempts) }
      .reject { it[:percent].zero? }
      .sort_by { -it[:percent] }
      .first(HARD_TOPIC_LIMIT)
  end

  private
    def students = @students ||= section.students.order(:name).to_a

    # What each student has finished **in this section's course**, keyed by user
    # id. One query for the cohort, exactly as Leaderboard#completions does for
    # the board — a LearnerProgress per roster row used to cost three queries a
    # student (its own rows, plus the course and topics it eagerly loads), which
    # made this screen 3n + 12 and the only page in the app whose cost grew with
    # the size of a section. It reads one thing from that object; this is it.
    def done_keys
      @done_keys ||= TopicCompletion.where(user: students, course: section.course)
                                    .includes(:topic)
                                    .group_by(&:user_id)
                                    .transform_values { |rows| rows.map(&:topic_key).to_set }
    end

    def student_row(user)
      done = done_keys.fetch(user.id, Set.new)

      Student.new(user:,
                  percent: percent(done.size, Syllabus.topic_count),
                  projects: (done & project_keys).size,
                  projects_total: project_keys.size,
                  seen: days_since_last_seen(user))
    end

    def project_keys = @project_keys ||= Syllabus.topics.select { it.kind == "project" }.map(&:key).to_set

    # The most recent thing this learner did — a topic finished or an answer
    # sent. Nil for someone who has done neither.
    def last_seen_at
      @last_seen_at ||= begin
        learned = TopicCompletion.where(user: students).group(:user_id).maximum(:learned_at)
        sent = Submission.where(user: students).group(:user_id).maximum(:created_at)

        learned.merge(sent) { |_id, a, b| [ a, b ].max }
      end
    end

    def days_since_last_seen(user)
      at = last_seen_at[user.id] or return nil

      (Date.current - at.in_time_zone.to_date).to_i
    end

    def stat_values
      [ "#{average_percent}%", "#{on_time_percent}%", inactive_count.to_s, average_score.to_s ]
    end

    # One query for the cohort, folded in Ruby — the same shape as `done_keys`
    # and `first_attempts`, and for the same reason: a per-student query would
    # make this screen's cost grow with the size of a section.
    def scored_attempts
      @scored_attempts ||= Submission.where(user: students).where.not(score: nil)
                                     .group_by { [ it.user_id, it.topic_id, it.kind ] }
                                     .transform_values { |attempts| attempts.map(&:score) }
    end

    # topic => the first submission each learner made against it.
    def first_attempts
      Submission.where(user: students, kind: "quiz")
                .includes(:topic)
                .order(:created_at, :id)
                .group_by(&:topic)
                .transform_values { it.group_by(&:user_id).values.map(&:first) }
    end

    def hard_topic_row(topic, attempts)
      failed = attempts.count { !it.passed? }

      { name: Syllabus.topic_name(topic.key), key: topic.key,
        percent: percent(failed, attempts.size), severity: severity_for(percent(failed, attempts.size)) }
    end

    def percent(part, whole) = whole.to_i.zero? ? 0 : (part * 100.0 / whole).round

    def csv_field(value)
      text = value.to_s
      text.match?(/[",\n]/) ? '"' + text.gsub('"', '""') + '"' : text
    end

    def severity_for(percent)
      return :alarm if percent >= ALARM_THRESHOLD
      return :warn  if percent >= WARN_THRESHOLD

      :notice
    end
end
