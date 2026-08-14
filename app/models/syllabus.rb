# The course-specific module breakdown shown on course pages and used by every
# lesson/progress boundary. Status is derived from a learner's completions; it is
# never stored on the taxonomy rows.
module Syllabus
  DEFAULT_COURSE = "AI1101"

  Topic_ = Data.define(:key, :name, :kind, :minutes, :done) do
    def kind_name = I18n.t("course.kind.#{kind}")
    def duration_text = I18n.t("units.minutes", count: minutes)
    def done? = done
    def applied? = Topic::APPLIED_KINDS.include?(kind.to_s)
  end

  Module_ = Data.define(:number, :status, :units, :topics, :title, :desc) do
    def desc? = desc.present?
    def status_name = I18n.t("course.status.#{status}")
    def done? = status == :done
    def current? = status == :now
    def locked? = status == :locked
    def meta_text = I18n.t("course.module_meta", topics: topics.size, units:)
  end

  APPLIED_KINDS = ::Topic::APPLIED_KINDS.map(&:to_sym).freeze

  class << self
    def entries(course = DEFAULT_COURSE)
      code = course_code(course)
      Current.syllabi ||= {}
      Current.syllabi[code] ||= begin
        own = Course.find_by!(code: code).course_modules.includes(:topics).to_a
        own.presence || (code == DEFAULT_COURSE ? own : entries(DEFAULT_COURSE))
      end
    end

    def reload!
      Current.syllabus = nil
      Current.syllabi = nil
      # The names are part of the syllabus read path now, so they go stale with
      # it. Forgetting the records but keeping their copy is how a reorder ends
      # up rendering the previous arrangement's names.
      SyllabusText.forget
    end

    def topics(course = DEFAULT_COURSE) = entries(course).flat_map(&:topics)
    def topic(key, course = DEFAULT_COURSE) = topics(course).find { it.key == key }

    def topic_key(module_number, position, course = DEFAULT_COURSE)
      ::Topic.key_for(module_number, position, course_code: course_code(course))
    end

    def topic_keys(course = DEFAULT_COURSE) = topics(course).map(&:key)

    def keys_in(module_number, course = DEFAULT_COURSE)
      entries(course).find { it.number == module_number }&.topics.to_a.map(&:key)
    end

    def applied_topic_keys(course = DEFAULT_COURSE) = topics(course).select(&:applied?).map(&:key)
    def topic_count(course = DEFAULT_COURSE) = topics(course).size
    def applied_topic_count(course = DEFAULT_COURSE) = applied_topic_keys(course).size

    def next_topic_key(done_keys, course = DEFAULT_COURSE)
      topic_keys(course).find { !done_keys.include?(it) }
    end

    def topic_after(key, course = DEFAULT_COURSE)
      keys = topic_keys(course)
      index = keys.index(key) or return nil

      keys[index + 1]
    end

    def topic_minutes(key, course = DEFAULT_COURSE) = topic(key, course)&.minutes.to_i

    def topic_name(key, course = DEFAULT_COURSE)
      topic = topic(key, course) or return ""
      named_topic(topic, curriculum(course)[topic.course_module.number - 1] || {})
    end

    def current_module_number(done_keys, course = DEFAULT_COURSE)
      entries(course).map(&:number).find { |number| !keys_in(number, course).all? { done_keys.include?(it) } }
    end

    def unlocked?(key, done_keys, course = DEFAULT_COURSE)
      current = current_module_number(done_keys, course)
      syllabus_topic = topic(key, course)
      syllabus_topic && (current.nil? || syllabus_topic.course_module.number <= current)
    end

    def modules(done_keys = Set.new, course = DEFAULT_COURSE)
      copy = curriculum(course)
      current = current_module_number(done_keys, course)

      code = course_code(course)

      entries(course).map do |mod|
        definition = copy[mod.number - 1] || {}
        Module_.new(
          number: mod.number,
          units: mod.units,
          status: module_status(mod.number, current),
          title: named_module(code, mod.number, :title, definition),
          desc: named_module(code, mod.number, :desc, definition),
          topics: mod.topics.map do |record|
            Topic_.new(
              key: record.key,
              kind: record.kind.to_sym,
              minutes: record.minutes,
              name: named_topic(record, definition),
              done: done_keys.include?(record.key)
            )
          end
        )
      end
    end

    def stats(course = DEFAULT_COURSE)
      record = Course.find_by!(code: course_code(course))
      [
        { value: topic_count(record).to_s, label: I18n.t("course.stats.topics") },
        { value: record.projects.to_s, label: I18n.t("course.stats.projects") },
        { value: I18n.t("units.hours", count: record.hours), label: I18n.t("course.stats.total_time") },
        { value: record.credits.to_s, label: I18n.t("course.stats.credits") }
      ]
    end

    def meta(course = DEFAULT_COURSE)
      record = Course.find_by!(code: course_code(course))
      [
        [ I18n.t("course.meta.code"), record.code ],
        [ I18n.t("course.meta.prerequisites"), I18n.t("course.meta.prerequisites_value") ],
        [ I18n.t("course.meta.assessment"), I18n.t("course.meta.assessment_value") ],
        [ I18n.t("course.meta.language"), I18n.t("course.meta.language_value") ]
      ]
    end

    private
      def course_code(course) = course.respond_to?(:code) ? course.code.to_s : course.to_s

      # A name in three tries: the override written against this topic's own key,
      # then the copy the curriculum shipped with at this position, then whatever
      # language the name was written in.
      #
      # The order is what makes a reorder safe. Position is the *fallback* now,
      # not the identity: a shipped topic that has never been touched still reads
      # out of the locale file, and the moment a builder moves one, the row keyed
      # on `topics.key` is what answers — so the lesson keeps its name instead of
      # inheriting its new neighbour's.
      def named_topic(record, definition)
        key = SyllabusText.topic_key(record.key)

        SyllabusText.for(key).presence ||
          definition.dig(:topics, record.position - 1).to_s.presence ||
          SyllabusText.any(key).to_s
      end

      # The same three tries for a module's title and description, keyed on the
      # module number, which a builder does not renumber.
      def named_module(code, number, field, definition)
        key = field == :title ? SyllabusText.module_title_key(code, number)
                              : SyllabusText.module_desc_key(code, number)

        SyllabusText.for(key).presence ||
          definition[field].to_s.presence ||
          SyllabusText.any(key).to_s
      end

      def curriculum(course)
        code = course_code(course)
        key = "course.curricula.#{code}.modules"
        I18n.exists?(key) ? I18n.t(key) : I18n.t("course.modules")
      end

      def module_status(number, current)
        return :done if current.nil? || number < current

        number == current ? :now : :locked
      end
  end
end
