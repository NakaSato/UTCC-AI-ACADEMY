# The module breakdown shown on the course page, and the list every lesson is a
# position in. Backed by `course_modules` and `topics` since the taxonomy became
# real; titles and topic names still come from `course.modules` in the locale
# files, indexed positionally.
#
# **Status is derived, not written.** A module is done when every one of its
# topics is, current when it is the first that is not, and locked after that —
# so what the course page shows and what the lesson lets a student open are the
# same rule, and finishing a topic really does open the next module. That is why
# no row carries a status column.
module Syllabus
  # Read models over a row. Both dodge a name: `Module_` dodges Ruby's, `Topic_`
  # dodges the record class this module reads from. The names never leave this
  # file — views only ever call the readers.
  Topic_ = Data.define(:key, :name, :kind, :minutes, :done) do
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

  # Which kinds of topic count as "applied" rather than just learned: the ones
  # where something is built. The My Learning bars are the split. Defined on the
  # record; kept here under the name the rest of the app already knew it by.
  APPLIED_KINDS = ::Topic::APPLIED_KINDS.map(&:to_sym).freeze

  # Course-level figures for the four stat tiles and the sidebar table. The topic
  # count is not among them: it is `topic_count`, counted off the rows, so the
  # number on the stat tile and the denominator under the progress bar cannot
  # disagree.
  PROJECT_COUNT = 6
  CREDITS = 3

  class << self
    # The whole syllabus in one query, folded in Ruby for the dozen different
    # cuts the screens ask for — the same trick LearnerProgress plays with a
    # learner's completions. Held on Current, so the cache lasts one request and
    # not the life of the process; see the note there for why that distinction
    # bites. `reload!` is for a caller that changes the taxonomy underneath, such
    # as db/seeds.rb.
    def entries = Current.syllabus ||= CourseModule.in_order.includes(:topics).to_a
    def reload! = Current.syllabus = nil

    def topics = entries.flat_map(&:topics)

    def topic(key) = topics.find { it.key == key }

    # "<module number>-<position>" — what a TopicCompletion is filed under.
    # Derived from the row rather than the locale files, so a key never changes
    # when copy does.
    def topic_key(module_number, position) = ::Topic.key_for(module_number, position)

    def topic_keys = topics.map(&:key)

    def keys_in(module_number)
      entries.find { it.number == module_number }&.topics.to_a.map(&:key)
    end

    def applied_topic_keys = topics.select(&:applied?).map(&:key)

    # How much there is to do. Every course reuses this one syllabus until each
    # has its own, so these are the denominators under every progress bar — and
    # the reason a course can be finished at all.
    def topic_count = topics.size
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

    # Time is not clocked anywhere, so the minutes budgeted for a topic are what
    # "hours studied" is counted from.
    def topic_minutes(key) = topic(key)&.minutes.to_i

    def topic_name(key)
      module_number, position = parse_key(key)
      I18n.t("course.modules").dig(module_number - 1, :topics, position - 1).to_s
    end

    # The module a learner is on: the first with a topic still unfinished. Nil
    # once the whole syllabus is done, which reads as "every module complete".
    def current_module_number(done_keys)
      entries.map(&:number).find { |number| !keys_in(number).all? { done_keys.include?(it) } }
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

      entries.map do |mod|
        Module_.new(
          number: mod.number, units: mod.units,
          status: module_status(mod.number, current),
          topics: mod.topics.map { |topic|
            Topic_.new(key: topic.key, kind: topic.kind.to_sym, minutes: topic.minutes,
                       name: names.dig(mod.number - 1, :topics, topic.position - 1).to_s,
                       done: done_keys.include?(topic.key))
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
  end
end
