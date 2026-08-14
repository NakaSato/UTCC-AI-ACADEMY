# The console's Overview tab, below the four counted tiles.
#
# The tab used to be the tiles and a note that said "other operational views will
# appear when their data sources are defined". These are those views, and every
# one of them is counted off records the app already keeps. Where a panel in the
# design had no honest source it is not here, and the omission is named:
#
# - **Directory sync.** The design draws a "Sync now" button beside the duplicate
#   list. There is no directory to sync with — ADR-0010 (UTCC SSO) is still a
#   draft — so the button would do nothing and say it had done it. The duplicate
#   *finding* is real and is here; the button is not.
# - **Merge and skip.** Merging two accounts means moving enrollments,
#   completions, submissions, proctor events and memberships from one to the
#   other and deciding which identity survives. That is a decision, not a button,
#   so the panel names the pair and links to the roster where an admin can act.
module AdminOverview
  # How far back an account counts as active. The same seven days the adoption
  # sub-line claims, and the same window `InstructorReport::INACTIVE_AFTER` uses
  # to decide who to chase.
  WINDOW = 7.days

  ACTIVITY_LIMIT = 6
  DUPLICATE_LIMIT = 5

  # A worker that has not checked in for this long is not running. Solid Queue
  # heartbeats far more often than this.
  HEARTBEAT = 5.minutes

  REPORTS = %w[ accounts courses audit ].freeze

  # ---- Adoption by unit -----------------------------------------------------

  Unit = Data.define(:name, :total, :active) do
    def pct = total.zero? ? 0 : (active * 100.0 / total).round
    def meta = I18n.t("admin.overview.adoption.meta", active:, total:)

    # Spelled as a name rather than a colour so the view keeps the palette.
    def severity
      return :good if pct >= 60
      pct >= 30 ? :warn : :low
    end
  end

  # Share of each faculty's accounts that did something in the last week.
  #
  # "Did something" is the union of the four things the app timestamps: signed
  # in, finished a topic, sent a submission, or performed an audited action.
  # Sessions alone would understate it badly — `Session` is deliberately never
  # touched after it is created, so a daily user who signed in a fortnight ago
  # has one row a fortnight old.
  def self.adoption
    totals = User.group(:faculty).count
    actives = User.where(id: active_user_ids).group(:faculty).count

    totals.map { |faculty, total| Unit.new(name: unit_name(faculty), total:, active: actives.fetch(faculty, 0)) }
          .sort_by { [ -it.pct, it.name ] }
  end

  def self.active_user_ids
    since = WINDOW.ago

    [ Session.where(created_at: since..),
      TopicCompletion.where(learned_at: since..),
      Submission.where(created_at: since..),
      AuditEvent.where(created_at: since..) ].flat_map { it.distinct.pluck(:user_id) }.uniq
  end

  # ---- Recent activity ------------------------------------------------------

  # The audit log's newest rows, as a feed rather than a table. The Audit tab is
  # still where the whole log lives, filtered and paged; this is the glance.
  def self.activity = AuditEvent.newest_first.includes(:user).limit(ACTIVITY_LIMIT)

  # Two letters from a name, in whatever script the name is written in.
  def self.initials(name)
    name.to_s.split.first(2).map { it[0] }.join.presence || "?"
  end

  # ---- Accounts that look like the same person ------------------------------

  # A count, and nothing that names anybody.
  #
  # `student_id`, `username` and `email_address` are each unique, so a person
  # with two accounts shows up as a shared name and nothing else. The finding is
  # worth surfacing; the people are not surfaced with it. SPEC-0012 invariant 5
  # holds this boundary to "aggregate values and approved labels, not raw learner
  # records or private identifiers", and a list of names beside their student IDs
  # is exactly the latter — so the panel reports how many names collide and how
  # many accounts are involved, and the roster, which is already the screen for
  # reading accounts, is where an administrator goes to look.
  #
  # Two students really can share a name, which is the other reason this is a
  # count rather than an accusation.
  Collisions = Data.define(:names, :accounts) do
    def any? = names.positive?
  end

  def self.duplicates
    counts = User.group(:name).having("COUNT(*) > 1").count

    Collisions.new(names: counts.size, accounts: counts.values.sum)
  end

  # ---- Service status -------------------------------------------------------

  Check = Data.define(:key, :state, :note) do
    def label = I18n.t("admin.overview.health.checks.#{key}")
    def state_name = I18n.t("admin.overview.health.state.#{state}")
  end

  # Read when the page is read, not on a timer. The design's caption says
  # "checked automatically every 5 minutes"; nothing in this app runs that
  # schedule, and a status page that reports a five-minute-old answer while
  # claiming to be live is worse than one that admits it is a spot check. All
  # four are cheap: a SELECT 1, one count, one cache round-trip, one stat.
  def self.health = [ database_check, jobs_check, cache_check, storage_check ]

  # Every check runs through here, so a service that is down answers "down"
  # rather than taking the console with it. A status panel that 500s is the one
  # failure mode a status panel may not have.
  def self.check(key)
    yield
  rescue StandardError => error
    Check.new(key:, state: :down, note: error.class.name)
  end

  def self.database_check
    check(:database) do
      ActiveRecord::Base.connection.select_value("SELECT 1")
      Check.new(key: :database, state: :ok, note: ActiveRecord::Base.connection.adapter_name)
    end
  end

  # A worker that is not running is not an error — nothing schedules one in
  # development, and the app's jobs are all fire-and-forget notifications — so
  # this warns rather than alarms.
  def self.jobs_check
    check(:jobs) do
      next Check.new(key: :jobs, state: :unknown, note: "") unless defined?(SolidQueue::Process)

      alive = SolidQueue::Process.where(last_heartbeat_at: HEARTBEAT.ago..).count
      Check.new(key: :jobs, state: alive.positive? ? :ok : :warn,
                note: I18n.t("admin.overview.health.workers", count: alive))
    end
  end

  # A round trip rather than a read: a cache that has lost its store answers
  # every read with nil, which is indistinguishable from a cold key. `fetch`
  # stores the block's value and hands it back, so one call proves both
  # directions — and a second `read` proves the value survived the call.
  def self.cache_check
    check(:cache) do
      probe = "admin_overview/health/#{SecureRandom.hex(4)}"
      stored = Rails.cache.fetch(probe, expires_in: 1.minute) { "1" }
      ok = stored == "1" && Rails.cache.read(probe) == "1"
      Rails.cache.delete(probe)

      Check.new(key: :cache, state: ok ? :ok : :warn, note: Rails.cache.class.name.demodulize)
    end
  end

  # Only the local disk service can be checked without reaching the network, and
  # local is what this app configures. Anything else answers "unknown" rather
  # than guessing.
  def self.storage_check
    check(:storage) do
      service = ActiveStorage::Blob.service
      name = service.class.name.demodulize
      next Check.new(key: :storage, state: :unknown, note: name) unless service.respond_to?(:root)

      writable = File.directory?(service.root) && File.writable?(service.root)
      Check.new(key: :storage, state: writable ? :ok : :warn, note: name)
    end
  end

  # ---- Reports --------------------------------------------------------------

  Report = Data.define(:key) do
    def label = I18n.t("admin.overview.reports.#{key}")
    def filename = "#{key}-#{Date.current.iso8601}.csv"
  end

  def self.reports = REPORTS.map { Report.new(key: it) }

  def self.report?(key) = REPORTS.include?(key.to_s)

  # Hand-rolled for the reason InstructorReport gives: Ruby 3.4 moved `csv` to a
  # bundled gem Bundler does not load, and a handful of columns do not earn a
  # dependency. The BOM is for Excel, which otherwise guesses Thai names into
  # mojibake.
  def self.report_csv(key)
    headers, rows = case key.to_s
    in "accounts" then accounts_report
    in "courses"  then courses_report
    in "audit"    then audit_report
    end

    "﻿" + ([ headers ] + rows).map { |row| row.map { csv_field(it) }.join(",") }.join("\n")
  end

  class << self
    private
      def unit_name(faculty) = faculty.presence || I18n.t("admin.overview.adoption.no_unit")

      def accounts_report
        headers = I18n.t("admin.overview.columns.accounts")
        rows = User.order(:role, :name).map do
          [ it.student_id.presence || it.username, it.name, I18n.t("admin.roles.#{it.role}"),
            it.faculty, I18n.l(it.created_at.to_date) ]
        end
        [ headers, rows ]
      end

      def courses_report
        headers = I18n.t("admin.overview.columns.courses")
        rows = AdminConsole.courses.map do
          [ it.code, it.name, it.state_name, it.sections.to_s, it.students.to_s ]
        end
        [ headers, rows ]
      end

      def audit_report
        headers = I18n.t("admin.overview.columns.audit")
        rows = AuditEvent.newest_first.includes(:user).map do
          [ it.created_at.in_time_zone.strftime("%Y-%m-%d %H:%M"), it.user.name,
            I18n.t("admin.audit.levels.#{it.level}"), it.text ]
        end
        [ headers, rows ]
      end

      def csv_field(value)
        text = value.to_s
        text.match?(/[",\n]/) ? '"' + text.gsub('"', '""') + '"' : text
      end
  end
end
