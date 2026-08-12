# One page of a list, and everything a pagination control needs to draw itself.
#
# The query budget counts queries, not rows, so a screen could ask four questions
# and render ten thousand answers and still pass. This is the bound on the other
# axis (ADR-0050): a paged list costs exactly one more query — the count — and
# never one per row.
#
# It wraps a relation rather than an array, so the page is taken in SQL with
# LIMIT/OFFSET rather than by loading everything and throwing most of it away.
# Offset paging is correct and cheap at this scale and gets slow at a depth
# nothing here reaches; the day a list has ten thousand rows, the fix is a cursor
# and a different object.
class Page
  include Enumerable

  # A judgement, not a measurement: what fits a laptop screen without scrolling
  # twice. One constant, one place — a screen that needs its own passes `size:`
  # and says why.
  SIZE = 25

  attr_reader :number, :size, :count

  def initialize(scope, number, size: SIZE)
    @scope = scope
    @size = size
    # `except(:order)` because a count does not need the sort and Postgres would
    # do the work anyway; `except(:limit, :offset)` so a scope that already
    # narrowed itself is counted as it stands rather than as this page.
    @count = scope.except(:order, :limit, :offset).count
    @number = clamped(number)
  end

  def records
    @records ||= @scope.offset((number - 1) * size).limit(size).to_a
  end

  # Enumerable gives the views `map`, `any?`, and the rest; `each` and `empty?`
  # are what a template actually reaches for, and neither comes free.
  def each(&) = records.each(&)

  def empty? = records.empty?

  def pages = @pages ||= [ (count / size.to_f).ceil, 1 ].max

  def first? = number == 1

  def last? = number >= pages

  def previous = number - 1

  def next = number + 1

  # A control on a single page is noise, so nothing renders one.
  def multiple? = pages > 1

  # The page numbers a control shows: the first, the last, and the current one
  # with its neighbours, with `nil` standing in for a gap. Twenty pages would
  # otherwise be twenty links, and the far ones are the ones nobody clicks.
  def window
    numbers = [ 1, pages, *(number - 1..number + 1) ].select { (1..pages).cover?(it) }.uniq.sort

    numbers.each_cons(2).flat_map { |left, right| right - left > 1 ? [ left, nil ] : [ left ] } + [ numbers.last ]
  end

  private
    # Whitelist-or-default, the rule `AdminConsole.tab_for` and `role_filter`
    # already run on: page 0, page 99 of 3, `page=abc`, and `page=-1` all land on
    # the nearest real page. `to_s` first, because `?page[]=1` hands this an
    # array and a URL a person edited is never a crash.
    def clamped(value) = value.to_s.to_i.clamp(1, pages)
end
