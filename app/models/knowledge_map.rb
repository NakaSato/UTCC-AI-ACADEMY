# The course-scoped knowledge map read model. Shape comes from Syllabus and
# mastery comes from the selected learner's completions and prior-knowledge
# marks; no map taxonomy or mastery counters are stored separately.
module KnowledgeMap
  Node = Data.define(:id, :total, :learned, :known, :leaf, :in_project, :children,
                     :label, :course_code, :topic_key, :prerequisite_keys) do
    def name = label
    def leaf? = leaf
    def known? = known
    def in_project? = in_project
    def prerequisite? = prerequisite_keys.any?
    def fully_learned? = learned >= total
    def partly_learned? = learned.positive? && !fully_learned?
    def remaining = total - learned
    def count_text = leaf? ? nil : "#{learned} / #{total}"

    def meta_text
      leaf? ? I18n.t("map.single_topic") : I18n.t("units.topics", count: total)
    end
  end

  DEFAULT_MODE = "course"
  Row = Data.define(:node, :depth)

  class << self
    # A course-scoped read model derived from the same syllabus and completions
    # as the course and progress screens.
    def curriculum(course_code, user: nil, mode: DEFAULT_MODE)
      course = Course.find_by(code: course_code) || Course.find_by!(code: Syllabus::DEFAULT_COURSE)
      code = course.code
      return [ empty_course_node(course) ] unless course.course_modules.exists?

      progress = user ? LearnerProgress.new(user) : nil
      done_keys = progress ? progress.map_keys_for(code) : Set.new
      known_keys = progress ? progress.prior_knowledge_keys_for(code) : Set.new
      syllabus_topics = Syllabus.topics(code)
      project_keys = syllabus_topics.select { it.kind == "project" }.map(&:key).to_set
      visible_keys = visible_topic_keys(syllabus_topics, project_keys, mode)
      modules = Syllabus.modules(done_keys, code).filter_map do |mod|
        topics = mod.topics.filter { visible_keys.include?(it.key) }
        next if topics.empty?

        children = topics.map do |topic|
          Node.new(
            id: topic.key,
            total: 1,
            learned: topic.done? ? 1 : 0,
            known: known_keys.include?(topic.key),
            leaf: true,
            in_project: topic.kind.to_s == "project",
            children: [],
            label: topic.name,
            course_code: code,
            topic_key: topic.key,
            prerequisite_keys: prerequisite_keys_for(topic.key, syllabus_topics, project_keys, mode)
          )
        end

        Node.new(
          id: "#{code}-module-#{mod.number}",
          total: children.sum(&:total),
          learned: children.sum(&:learned),
          known: false,
          leaf: false,
          in_project: false,
          children:,
          label: mod.title,
          course_code: code,
          topic_key: nil,
          prerequisite_keys: []
        )
      end

      [ Node.new(
        id: code,
        total: modules.sum(&:total),
        learned: modules.sum(&:learned),
        known: false,
        leaf: false,
        in_project: false,
        children: modules,
        label: I18n.t("catalog.courses.#{code}.title"),
        course_code: code,
        topic_key: nil,
        prerequisite_keys: []
      ) ]
    end

    # Every node in render order. Closed groups' descendants are omitted so the
    # DOM stays small and the URL remains the only navigation state.
    def rows(open:, nodes:, depth: 0, into: [])
      nodes.each do |node|
        into << Row.new(node:, depth:)
        rows(open:, nodes: node.children, depth: depth + 1, into:) if open.include?(node.id)
      end
      into
    end

    # The node plus its ancestors, which is exactly the breadcrumb trail.
    def path_to(id, nodes:, trail: [])
      nodes.each do |node|
        branch = trail + [ node ]
        return branch if node.id == id

        found = path_to(id, nodes: node.children, trail: branch)
        return found if found
      end
      nil
    end

    def find(id, nodes:) = path_to(id, nodes:)&.last

    private
      def visible_topic_keys(topics, project_keys, mode)
        return topics.map(&:key).to_set unless mode.to_s == "project"

        project_keys.each_with_object(Set.new) do |project_key, keys|
          topics.each do |topic|
            keys << topic.key
            break if topic.key == project_key
          end
        end
      end

      def prerequisite_keys_for(key, topics, project_keys, mode)
        return [] unless mode.to_s == "project" && project_keys.include?(key)

        topics.take_while { it.key != key }.map(&:key)
      end

      def empty_course_node(course)
        Node.new(
          id: course.code,
          total: 0,
          learned: 0,
          known: false,
          leaf: false,
          in_project: false,
          children: [],
          label: I18n.t("catalog.courses.#{course.code}.title"),
          course_code: course.code,
          topic_key: nil,
          prerequisite_keys: []
        )
      end
  end
end
