# The topic tree behind the knowledge map. Node names live in
# config/locales under `map.nodes.<id>`; the counts and the shape live here.
module KnowledgeMap
  Node = Data.define(:id, :total, :learned, :leaf, :in_project, :children) do
    def name = I18n.t("map.nodes.#{id}")
    def leaf? = leaf
    def in_project? = in_project
    def fully_learned? = learned >= total
    def partly_learned? = learned.positive? && !fully_learned?
    def remaining = total - learned
    def count_text = leaf? ? nil : "#{learned} / #{total}"

    def meta_text
      leaf? ? I18n.t("map.single_topic") : I18n.t("units.topics", count: total)
    end
  end

  # id, total, learned, options, children
  TREE = [
    [ "cs", 86, 24, {}, [
      [ "prog", 28, 19, {}, [
        [ "py", 16, 14, {}, [
          [ "py-var",  1, 1, { leaf: true } ],
          [ "py-flow", 1, 1, { leaf: true } ],
          [ "py-fn",   1, 0, { leaf: true, in_project: true } ]
        ] ],
        [ "pd", 12, 5, {}, [
          [ "pd-df",    1, 1, { leaf: true } ],
          [ "pd-clean", 1, 0, { leaf: true, in_project: true } ]
        ] ]
      ] ],
      [ "ml", 38, 5, {}, [
        [ "ml-prep", 16, 5, {}, [
          [ "ml-split", 1, 1, { leaf: true } ],
          [ "ml-scale", 1, 0, { leaf: true, in_project: true } ],
          [ "ml-enc",   1, 0, { leaf: true } ]
        ] ],
        [ "ml-sup", 14, 0, {}, [
          [ "ml-lin",  1, 0, { leaf: true, in_project: true } ],
          [ "ml-tree", 1, 0, { leaf: true } ]
        ] ],
        [ "ml-eval", 8, 0, {}, [
          [ "ml-cm", 1, 0, { leaf: true } ],
          [ "ml-of", 1, 0, { leaf: true, in_project: true } ]
        ] ]
      ] ],
      [ "gen", 14, 0, {}, [
        [ "gen-llm", 8, 0, {}, [
          [ "gen-tok", 1, 0, { leaf: true } ]
        ] ],
        [ "gen-pp", 6, 0, {}, [
          [ "gen-few", 1, 0, { leaf: true, in_project: true } ]
        ] ]
      ] ],
      [ "eth", 6, 0, {}, [
        [ "eth-pdpa", 1, 0, { leaf: true } ]
      ] ]
    ] ]
  ].freeze

  # Groups that start expanded, matching the design's default state.
  DEFAULT_OPEN = %w[ cs prog py ml ml-prep gen ].freeze
  DEFAULT_SELECTED = "ml-prep"

  Row = Data.define(:node, :depth)

  class << self
    def roots = TREE.map { |entry| build(entry) }

    # Every node in render order, with the depth the sidebar indents by.
    # `open` is the set of expanded group ids; children of a closed group are
    # skipped entirely rather than hidden, so the DOM stays small.
    def rows(open: DEFAULT_OPEN, nodes: roots, depth: 0, into: [])
      nodes.each do |node|
        into << Row.new(node:, depth:)
        rows(open:, nodes: node.children, depth: depth + 1, into:) if open.include?(node.id)
      end
      into
    end

    # The node plus its ancestors, which is exactly the breadcrumb trail.
    def path_to(id, nodes: roots, trail: [])
      nodes.each do |node|
        branch = trail + [ node ]
        return branch if node.id == id

        found = path_to(id, nodes: node.children, trail: branch)
        return found if found
      end
      nil
    end

    def find(id) = path_to(id)&.last

    # Flat list of every node, used by the header search.
    def each_node(nodes: roots, trail: [], into: [])
      nodes.each do |node|
        into << [ node, trail ]
        each_node(nodes: node.children, trail: trail + [ node ], into:)
      end
      into
    end

    private
      def build(entry)
        id, total, learned, options, children = entry
        Node.new(
          id:, total:, learned:,
          leaf: options.fetch(:leaf, false),
          in_project: options.fetch(:in_project, false),
          children: (children || []).map { |child| build(child) }
        )
      end
  end
end
