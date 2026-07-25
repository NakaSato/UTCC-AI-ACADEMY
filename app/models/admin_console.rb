# The admin console's five placeholder tabs.
#
# The sixth tab, Users, is NOT here — it is the real roster, backed by the
# `role` column and `AdminController#update`. Everything in this file is
# fabricated the way the rest of app/models is: numbers and taxonomy in Ruby,
# every readable word in `admin.*` in the locale files, joined BY INDEX.
#
# Add a row here and you must add one to both locale files, or every label
# after it shifts. `placeholder_content_test.rb` asserts the lengths agree.
module AdminConsole
  TABS = %i[ features overview users courses queue audit ].freeze

  # ---- Feature control ------------------------------------------------------

  # A toggle is on/off; a select carries its option keys. `on:` is the shipped
  # default — nothing here is persisted, so it is also the only state there is.
  Flag = Data.define(:key, :group, :position, :kind, :on, :options) do
    def name = copy[:name]
    def scope = copy[:scope]
    def desc = copy[:desc]
    def toggle? = kind == :toggle
    def state_note = I18n.t("admin.features.state.#{on ? :on : :off}")

    def option_labels = options.map { |o| [ o, I18n.t("admin.features.options.#{o}") ] }

    private

    def copy = I18n.t("admin.features.groups")[group][:items][position]
  end

  FLAG_GROUPS = [
    [ [ :learning_map, :toggle, true,  nil ],
      [ :search,       :toggle, true,  nil ],
      [ :notifications, :toggle, true, nil ],
      [ :catalog_cols, :select, nil,   %w[ two three ] ] ],
    [ [ :gamify,      :toggle, true,  nil ],
      [ :hearts,      :toggle, true,  nil ],
      [ :lives_cap,   :select, nil,   %w[ three five ] ],
      [ :leaderboard, :toggle, true,  nil ] ],
    [ [ :proctoring,  :toggle, true,  nil ],
      [ :language,    :select, nil,   %w[ th en ] ] ]
  ].freeze

  # ---- Overview -------------------------------------------------------------

  # value, and whether the note reads as good / neutral / warning.
  STATS = [
    [ "2,184", :good ], [ "12", :neutral ], [ "38", :warn ], [ "71%", :good ]
  ].freeze

  # percent adopted — the bar colour follows the number, not a stored choice.
  ADOPTION = [ 78, 71, 54, 39 ].freeze

  # The activity feed flags one row as an integrity alert; that row gets the
  # crimson avatar plate rather than the neutral one.
  ACTIVITY_ALERT_INDEX = 2
  ACTIVITY_COUNT = 5

  # ok | warn, one per service row.
  HEALTH = %i[ ok warn ok ok warn ].freeze

  # ---- Courses --------------------------------------------------------------

  # code, sections, students. A course with no students is a draft; the rest
  # are live until an admin hides them.
  COURSES = [
    [ "AI1101", 6, 284 ], [ "AI1150", 3, 128 ], [ "AI2101", 2, 74 ],
    [ "AI2180", 2, 61 ], [ "AI2204", 2, 0 ]
  ].freeze

  CourseRow = Data.define(:code, :sections, :students, :position) do
    def name = copy[:name]
    def faculty = copy[:faculty]
    def owner = copy[:owner]
    def draft? = students.zero?
    def state = draft? ? :draft : :live
    def state_name = I18n.t("admin.courses.state.#{state}")

    private

    def copy = I18n.t("admin.courses.rows")[position]
  end

  # ---- Approval queue -------------------------------------------------------

  # Which tone the kind pill takes. All four ship pending; deciding one would
  # need somewhere to write the decision.
  QUEUE_KINDS = %i[ access course content data ].freeze

  QueueItem = Data.define(:kind, :position) do
    def title = copy[:title]
    def label = copy[:label]
    def meta = copy[:meta]
    def when_text = copy[:when]

    private

    def copy = I18n.t("admin.queue.rows")[position]
  end

  # ---- Audit log ------------------------------------------------------------

  # info | warn, one per entry.
  AUDIT_LEVELS = %i[ info info info warn warn info ].freeze

  class << self
    def tab_for(param)
      TABS.include?(param.to_s.to_sym) ? param.to_s.to_sym : :users
    end

    def flags
      FLAG_GROUPS.flat_map.with_index do |items, group|
        items.each_with_index.map do |(key, kind, on, options), position|
          Flag.new(key:, group:, position:, kind:, on:, options:)
        end
      end
    end

    def flag_groups = flags.group_by(&:group).values

    # The Feature-control tab badge counts what an admin has switched OFF,
    # because that is the number worth noticing.
    def flags_off = flags.count { it.toggle? && !it.on }

    def stats
      copy = I18n.t("admin.overview.stats")
      STATS.each_with_index.map do |(value, tone), index|
        { value:, tone:, label: copy[index][:label], note: copy[index][:note] }
      end
    end

    def adoption
      copy = I18n.t("admin.overview.adoption")
      ADOPTION.each_with_index.map do |percent, index|
        { percent:, name: copy[index][:name], meta: copy[index][:meta] }
      end
    end

    def activity
      copy = I18n.t("admin.overview.activity")
      ACTIVITY_COUNT.times.map do |index|
        { alert: index == ACTIVITY_ALERT_INDEX, text: copy[index][:text],
          who: copy[index][:who], when_text: copy[index][:when] }
      end
    end

    def health
      copy = I18n.t("admin.overview.health")
      HEALTH.each_with_index.map do |state, index|
        { state:, label: copy[index][:label], note: copy[index][:note] }
      end
    end

    def courses
      COURSES.each_with_index.map do |(code, sections, students), position|
        CourseRow.new(code:, sections:, students:, position:)
      end
    end

    def queue
      QUEUE_KINDS.each_with_index.map { |kind, position| QueueItem.new(kind:, position:) }
    end

    def pending_count = queue.size

    def audit
      copy = I18n.t("admin.audit.rows")
      AUDIT_LEVELS.each_with_index.map do |level, index|
        { level:, stamp: copy[index][:stamp], actor: copy[index][:actor], event: copy[index][:event] }
      end
    end

    # Only two tabs carry a badge; the rest would show a meaningless zero.
    def badge_for(tab)
      case tab
      in :features then flags_off
      in :queue    then pending_count
      else nil
      end
    end
  end
end
