require "test_helper"

# The object behind every paged list (ADR-0050). The screens are asserted in
# `test/controllers/paged_lists_test.rb`; this is the arithmetic and the
# clamping, which is where a pagination control usually goes wrong: page 0, the
# page after the last one, and a URL somebody typed by hand.
class PageTest < ActiveSupport::TestCase
  # The arithmetic is asserted against exact counts, so the table starts empty
  # rather than at whatever the fixtures happen to hold.
  setup do
    @actor = users(:admin)
    AuditEvent.delete_all
  end

  def record_events(count)
    count.times { AuditEvent.create!(user: @actor, action: "enrolled", params: { name: "x", label: "y" }) }
  end

  def scope = AuditEvent.newest_first

  test "a page holds at most SIZE rows however many there are" do
    record_events(Page::SIZE * 2 + 3)

    assert_equal Page::SIZE, Page.new(scope, 1).records.length
    assert_equal Page::SIZE, Page.new(scope, 2).records.length
    assert_equal 3, Page.new(scope, 3).records.length
  end

  test "the pages divide the count, and a short last page still counts" do
    record_events(Page::SIZE + 1)
    page = Page.new(scope, 1)

    assert_equal AuditEvent.count, page.count
    assert_equal 2, page.pages
  end

  test "an empty list is one page, not zero" do
    page = Page.new(scope, 1)

    assert_equal 1, page.pages
    assert_equal 1, page.number
    assert_empty page
    assert_not page.multiple?
  end

  # Whitelist-or-default, the rule the console's other params already run on: a
  # URL a person edited lands on the nearest real page rather than a 404 or an
  # empty screen.
  test "an impossible page number clamps to a real one" do
    record_events(Page::SIZE + 1)

    assert_equal 1, Page.new(scope, "0").number
    assert_equal 1, Page.new(scope, "-1").number
    assert_equal 1, Page.new(scope, "abc").number
    assert_equal 1, Page.new(scope, nil).number
    assert_equal 1, Page.new(scope, [ "1", "2" ]).number
    assert_equal 2, Page.new(scope, "99").number
    assert_equal 2, Page.new(scope, 2).number
  end

  test "a page past the end holds the last page's rows rather than nothing" do
    record_events(Page::SIZE + 2)

    assert_equal Page.new(scope, 2).records.map(&:id), Page.new(scope, 500).records.map(&:id)
    assert_equal 2, Page.new(scope, 500).records.length
  end

  # The whole point of a bound is lost if reaching for it grows the query count.
  test "a page costs the rows and the count, and nothing per row" do
    record_events(Page::SIZE * 2)
    small = count_queries { Page.new(scope, 1).records }

    record_events(Page::SIZE * 2)
    large = count_queries { Page.new(scope, 1).records }

    assert_equal 2, small, "a page is one count and one read"
    assert_equal small, large, "the page went from #{small} to #{large} queries as the list grew"
  end

  test "the page is taken in SQL rather than out of a list loaded whole" do
    record_events(Page::SIZE + 5)

    assert_match(/LIMIT/i, sql_for { Page.new(scope, 2).records })
    assert_match(/OFFSET/i, sql_for { Page.new(scope, 2).records })
  end

  # Twenty pages is twenty links, and the far ones are the ones nobody clicks.
  test "the window shows the ends, the current page, and a gap for the rest" do
    record_events(Page::SIZE * 12)

    assert_equal [ 1, 2, 3, nil, 12 ], Page.new(scope, 2).window
    assert_equal [ 1, nil, 5, 6, 7, nil, 12 ], Page.new(scope, 6).window
    assert_equal [ 1, nil, 11, 12 ], Page.new(scope, 12).window
  end

  test "a short list shows every page and no gap" do
    record_events(Page::SIZE * 2 + 1)

    assert_equal [ 1, 2, 3 ], Page.new(scope, 1).window
  end

  # A screen may pass its own size with a sentence saying why; nothing does yet,
  # and the object still has to honour it.
  test "a screen can pass its own size" do
    record_events(10)

    assert_equal 5, Page.new(scope, 1, size: 5).records.length
    assert_equal 2, Page.new(scope, 1, size: 5).pages
  end

  private
    def count_queries
      count = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
        next if payload[:sql] =~ /\A\s*(BEGIN|COMMIT|RELEASE|SAVEPOINT)/i
        count += 1
      end
      yield
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    def sql_for
      statements = []
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        statements << payload[:sql]
      end
      yield
      statements.join("\n")
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end
end
