# The module breakdown shown on the course page, and the list every lesson is a
# position in. Titles and topic names come from `course.modules` in the locale
# files, indexed positionally; the knowledge-unit count, topic kind and duration
# live here.
#
# **Status is derived, not written.** A module is done when every one of its
# topics is, current when it is the first that is not, and locked after that —
# so what the course page shows and what the lesson lets a student open are the
# same rule, and finishing a topic really does open the next module.
module Syllabus
  Topic = Data.define(:key, :name, :kind, :minutes, :done) do
    def kind_name = I18n.t("course.kind.#{kind}")
    def duration_text = I18n.t("units.minutes", count: minutes)
    def done? = done

    # Which of the two My Learning bars finishing this topic fills.
    def applied? = APPLIED_KINDS.include?(kind)
  end

  Module_ = Data.define(:number, :status, :units, :topics) do
    def title = I18n.t("course.modules")[number - 1][:title]

    # Optional: a module without a `desc:` in the locale file simply renders
    # none, which is how the design ships until an instructor writes one.
    def desc = I18n.t("course.modules")[number - 1][:desc]
    def desc? = desc.present?

    def status_name = I18n.t("course.status.#{status}")
    def done? = status == :done
    def current? = status == :now
    def locked? = status == :locked
    def meta_text = I18n.t("course.module_meta", topics: topics.size, units:)
  end

  # knowledge units, [[kind, minutes], …] — one pair per topic, in the same
  # order as the topic names in the locale file.
  ENTRIES = [
    [ 12, [ [ :theory, 8 ], [ :theory, 10 ], [ :exercise, 15 ] ] ],
    [ 18, [ [ :theory, 9 ], [ :theory, 12 ], [ :mix, 14 ], [ :code, 20 ] ] ],
    [ 22, [ [ :code, 18 ], [ :code, 24 ] ] ],
    [ 15, [ [ :theory, 11 ], [ :exercise, 16 ] ] ],
    [ 14, [ [ :theory, 12 ], [ :project, 40 ] ] ],
    [ 10, [ [ :theory, 10 ], [ :theory, 12 ] ] ]
  ].freeze

  # Which kinds of topic count as "applied" rather than just learned: the ones
  # where something is built. The My Learning bars are the split.
  APPLIED_KINDS = %i[ exercise code project mix ].freeze

  # Course-level figures for the four stat tiles and the sidebar table. The topic
  # count is not among them: it is `topic_count`, counted off ENTRIES, so the
  # number on the stat tile and the denominator under the progress bar cannot
  # disagree.
  PROJECT_COUNT = 6
  CREDITS = 3

  class << self
    # "<module number>-<position>" — what a TopicCompletion is filed under, since
    # there is no Topic table to point at. Derived from ENTRIES rather than from
    # the locale files, so a key never changes when copy does.
    def topic_key(module_number, position) = "#{module_number}-#{position}"

    def topic_keys
      ENTRIES.each_with_index.flat_map do |(_units, topics), index|
        topics.each_index.map { topic_key(index + 1, it + 1) }
      end
    end

    def keys_in(module_number)
      topics = ENTRIES.dig(module_number - 1, 1) or return []
      topics.each_index.map { topic_key(module_number, it + 1) }
    end

    def applied_topic_keys
      topic_keys.select { APPLIED_KINDS.include?(topic_entry(it).first) }
    end

    # How much there is to do. Every course reuses this one syllabus until real
    # modules land, so these are the denominators under every progress bar —
    # and the reason a course can be finished at all.
    def topic_count = topic_keys.size
    def applied_topic_count = applied_topic_keys.size

    # The first topic a learner has not finished — what "next up" means on the
    # dashboard. Nil once the syllabus is exhausted.
    def next_topic_key(done_keys) = topic_keys.find { !done_keys.include?(it) }

    # The one after this in reading order, regardless of what is finished: where
    # the summary step's "next topic" button goes. Nil at the end.
    def topic_after(key)
      index = topic_keys.index(key) or return nil

      topic_keys[index + 1]
    end

    # Time is not clocked anywhere, so the minutes budgeted for a topic here are
    # what "hours studied" is counted from.
    def topic_minutes(key) = topic_entry(key)&.last.to_i

    def topic_name(key)
      module_number, position = parse_key(key)
      I18n.t("course.modules").dig(module_number - 1, :topics, position - 1).to_s
    end

    # The module a learner is on: the first with a topic still unfinished. Nil
    # once the whole syllabus is done, which reads as "every module complete".
    def current_module_number(done_keys)
      (1..ENTRIES.size).find { |number| !keys_in(number).all? { done_keys.include?(it) } }
    end

    # What the lesson is allowed to open. Locked is a real gate rather than
    # decoration: a topic in a later module cannot be reached until the modules
    # before it are finished.
    def unlocked?(key, done_keys)
      return false unless topic_keys.include?(key)

      current = current_module_number(done_keys)
      current.nil? || parse_key(key).first <= current
    end

    def modules(done_keys = Set.new)
      names = I18n.t("course.modules")
      current = current_module_number(done_keys)

      ENTRIES.each_with_index.map do |(units, topics), index|
        number = index + 1

        Module_.new(
          number:, units:, status: module_status(number, current),
          topics: topics.each_with_index.map { |(kind, minutes), position|
            key = topic_key(number, position + 1)
            Topic.new(key:, name: names[index][:topics][position], kind:, minutes:,
                      done: done_keys.include?(key))
          }
        )
      end
    end

    def stats
      [
        { value: topic_count.to_s,                    label: I18n.t("course.stats.topics") },
        { value: PROJECT_COUNT.to_s,                  label: I18n.t("course.stats.projects") },
        { value: I18n.t("course.stats.total_time_value"), label: I18n.t("course.stats.total_time") },
        { value: CREDITS.to_s,                        label: I18n.t("course.stats.credits") }
      ]
    end

    def meta
      [
        [ I18n.t("course.meta.code"), "AI1101" ],
        [ I18n.t("course.meta.prerequisites"), I18n.t("course.meta.prerequisites_value") ],
        [ I18n.t("course.meta.assessment"),    I18n.t("course.meta.assessment_value") ],
        [ I18n.t("course.meta.language"),      I18n.t("course.meta.language_value") ]
      ]
    end

    private
      def module_status(number, current)
        return :done if current.nil? || number < current

        number == current ? :now : :locked
      end

      def parse_key(key) = key.to_s.split("-", 2).map(&:to_i)

      def topic_entry(key)
        module_number, position = parse_key(key)
        return nil unless module_number.positive? && position.positive?

        ENTRIES.dig(module_number - 1, 1, position - 1)
      end
  end
end
