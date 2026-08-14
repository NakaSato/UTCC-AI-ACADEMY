# The admin console's backed tabs and its small live Overview boundary.
#
# Four tabs are NOT here, because they are backed by records rather than by this
# file: Users is the real roster (the `role` column and `AdminController#update`),
# Sections is real cohorts, Integrity reads `proctor_events` through `Proctoring`,
# and Landing is the marketing page's copy (`LandingText`, over `Landing`).
# Feature settings are the approved typed allow-list in `FeatureSetting`; every
# readable word in `admin.*` in the locale files is still joined BY INDEX.
#
# Add a row here and you must add one to both locale files, or every label
# after it shifts. `placeholder_content_test.rb` asserts the lengths agree.
module AdminConsole
  TABS = %i[ features overview users courses landing sections queue proposals integrity perms audit ].freeze

  # ---- The dark header ------------------------------------------------------

  # The admin screen is backed by records, so its head stats are counts, not
  # copy. Labels are `admin.head.stats`, positional as ever.
  def self.head_stats
    values = [
      User.count, User.student.count, User.instructor.count + User.admin.count,
      Section.count, TopicCompletion.count
    ]

    I18n.t("admin.head.stats").zip(values).map { |label, value| { label:, value: } }
  end

  # ---- Feature control ------------------------------------------------------

  # Every rendered row comes from the approved FeatureSetting allow-list. The
  # record may be absent after a replant, so the model supplies its safe default.
  Flag = Data.define(:key, :group, :position, :enabled, :lock_version) do
    def name = copy[:name]
    def scope = copy[:scope]
    def desc = copy[:desc]
    def toggle? = true
    def state_note = I18n.t("admin.features.state.#{enabled ? :on : :off}")

    private

    def copy = I18n.t("admin.features.groups")[group][:items][position]
  end

  FLAG_GROUPS = [
    [ :search, :notifications ],
    [ :leaderboard ]
  ].freeze

  # ---- Courses --------------------------------------------------------------

  # The Courses tab is a read model over the persisted catalog and cohort
  # records. It deliberately exposes no owner/faculty field until those have a
  # source of truth rather than deriving them from locale copy.
  CourseRow = Data.define(:record, :sections, :students) do
    def code = record.code
    def name = I18n.t("catalog.courses.#{code}.title")
    def state = record.lifecycle_state.to_sym
    def state_name = I18n.t("admin.courses.state.#{state}")
    def available_transitions = record.available_transitions
  end

  # ---- Permissions matrix ---------------------------------------------------

  # One row per capability, one flag per role in User::ROLES order. Every row is
  # a true statement about the code — the leaderboard really does rank students
  # only, proctoring really is student-only, and the two staff gates are the two
  # `allow_only` declarations. Change a gate and this table is lying until it
  # changes too; the row labels are `admin.perms.rows`, positional.
  PERMS = [
    [ true,  true,  true  ],   # learn lessons, record progress
    [ true,  false, false ],   # appear on the leaderboard
    [ true,  false, false ],   # proctoring active in lessons
    [ false, true,  true  ],   # open the Teaching console
    [ false, false, true  ],   # open this console
    [ false, false, true  ]    # grant roles
  ].freeze

  # The Users tab's role chips and the audit levels. :all is a chip, not a
  # role, so it can never leak into a where().
  ROLE_FILTERS = [ :all, *User::ROLES.map(&:to_sym) ].freeze
  LEVEL_FILTERS = %i[ all info warn ].freeze

  # How the roster may be ordered. A whitelist mapping to an ORDER BY this module
  # owns, never a column name off the query string — and applied before the page
  # is taken, or the second page would be the second page of a different order
  # (ADR-0050).
  #
  # `role` keeps its secondary sort by name, because a roster grouped by role and
  # then by nothing is a roster you still cannot find anybody in.
  SORTS = {
    role: [ :role, :name ],
    name: [ :name ],
    joined: [ { created_at: :desc }, :name ],
    faculty: [ { faculty: :asc }, :name ]
  }.freeze
  DEFAULT_SORT = :role

  # What an admin can create a console account as. Two of the three are roles on
  # the user; "company" is not, and never becomes one — a company account is an
  # ordinary account plus an active organization membership. See ADR-0024.
  CONSOLE_ACCESS = %w[ instructor admin company ].freeze

  # ---- Audit log ------------------------------------------------------------

  # The rows are NOT here any more — they are `audit_events`, written by the
  # admin actions themselves. `LEVEL_FILTERS` stays, because the `?level=` chips
  # are still a whitelist this module owns; `AuditEvent::WARN` decides which
  # actions land in which.

  class << self
    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : :users
    end

    def flags
      FLAG_GROUPS.flat_map.with_index do |items, group|
        items.each_with_index.map do |key, position|
          setting = FeatureSetting.admin_rows.find { it.key == key.to_s }
          Flag.new(key:, group:, position:, enabled: setting.enabled,
                   lock_version: setting.lock_version)
        end
      end
    end

    def flag_groups = flags.group_by(&:group).values

    # The Feature-control tab badge counts approved settings switched off,
    # because that is the number worth noticing.
    def flags_off = flags.count { !it.enabled }

    def stats
      values = [
        User.count, User.student.count, User.instructor.count + User.admin.count,
        TopicCompletion.count
      ]
      copy = I18n.t("admin.overview.stats")
      values.each_with_index.map do |value, index|
        { value: value.to_fs(:delimited), tone: %i[ good neutral neutral good ][index],
          label: copy[index][:label], note: copy[index][:note] }
      end
    end

    # `matching` filters by code or localized name, so the search box works in
    # whichever language the console is being read in.
    def courses(matching: nil)
      rows = Course.in_catalog_order.includes(:sections, :enrollments).map do |record|
        CourseRow.new(record:, sections: record.sections.size, students: record.enrollments.size)
      end
      return rows if matching.blank?

      needle = matching.downcase
      rows.select { it.code.downcase.include?(needle) || it.name.downcase.include?(needle) }
    end

    # A relation, not an array: the console pages it, and a page has to be taken
    # in SQL rather than out of a list that was loaded whole first.
    def queue
      ApprovalRequest.includes(:course, :requester, :decisions).newest_first
    end

    def pending_count = ApprovalRequest.pending.count

    # ---- Proposals ----------------------------------------------------------

    # Every proposal, newest first, with the decisions that answered it. The
    # console is the only screen that reads somebody else's proposal at all —
    # SPEC-0050's access contract, and SPEC-0049's before it.
    def proposals
      ProposalRequest.includes(:user, :decisions).newest_first
    end

    def undecided_proposal_count = ProposalRequest.undecided.count

    def queue_sla
      pending = ApprovalRequest.pending
      oldest = pending.minimum(:created_at)
      approved_this_month = ApprovalDecision.approved.where(created_at: Time.current.beginning_of_month..).count

      [
        { label: I18n.t("admin.queue.sla.oldest"), value: oldest ? I18n.l(oldest, format: :short) : I18n.t("admin.queue.sla.none") },
        { label: I18n.t("admin.queue.sla.pending"), value: pending.count.to_s },
        { label: I18n.t("admin.queue.sla.approved"), value: approved_this_month.to_s }
      ]
    end

    def perm_rows
      I18n.t("admin.perms.rows").zip(PERMS).map { |label, flags| { label:, flags: } }
    end

    def role_filter(param)
      ROLE_FILTERS.include?(param.to_s.to_sym) ? param.to_s.to_sym : :all
    end

    def level_filter(param)
      LEVEL_FILTERS.include?(param.to_s.to_sym) ? param.to_s.to_sym : :all
    end

    def sort_filter(param)
      SORTS.key?(param.to_s.to_sym) ? param.to_s.to_sym : DEFAULT_SORT
    end

    # Only the tabs with something waiting carry a badge; the rest would show a
    # meaningless zero.
    def badge_for(tab)
      case tab
      in :features  then flags_off
      in :queue     then pending_count
      in :proposals then undecided_proposal_count
      in :integrity then Proctoring.open_case_count
      else nil
      end
    end
  end
end
