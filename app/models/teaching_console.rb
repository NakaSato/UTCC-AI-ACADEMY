# The Teaching console's tab bar.
#
# The screen used to stack four panels down one column — the cohort figures, the
# course, the integrity switches, then the topics-and-roster split — in the order
# they happened to be built. A teacher opening it to answer "who is behind?" read
# past two panels of settings to get there.
#
# So it tabs, the way the admin console does, with the same component: the URL is
# the state, an unknown tab opens the default rather than nothing, and a count
# rides on a tab only when it means something needs attention.
class TeachingConsole
  # Order matters — it is the order of the bar. Roster first because it is the
  # question the screen is opened with.
  TABS = %i[ roster topics course syllabus integrity ].freeze
  DEFAULT_TAB = :roster

  # The two tabs that are about a teacher's own course rather than about their
  # section. An administrator holding the staff role teaches nothing (ADR-0054)
  # and is offered neither, exactly as they were offered no course panel before.
  COURSE_TABS = %i[ course syllabus ].freeze

  def self.tabs_for(course:) = course ? TABS : TABS - COURSE_TABS

  # Whitelist-or-default, like `AdminConsole.tab_for`. A `?tab=course` typed by
  # someone who teaches nothing lands on the roster rather than on an error.
  def self.tab_for(param, course:)
    tabs_for(course:).find { it.to_s == param.to_s } || DEFAULT_TAB
  end

  # What is off its default and worth a look, never a plain size: the roster
  # counts the students who are behind, not the students. A tab whose figure is
  # zero wears no pill.
  def self.badges(report:, integrity_settings:)
    { roster: report.behind_count, integrity: integrity_settings.count { !it.enabled } }
  end
end
