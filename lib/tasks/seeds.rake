# Fixture coverage for the seeded database.
#
# Rails empties a table between tests only when a fixture file names it. CI
# replants the seeds into the test database, so a table the seeds write but the
# fixtures do not name keeps its rows through the next fixture load — still
# pointing at parent records the fixtures have just deleted. Every test that
# loads fixtures then dies on a foreign key before reaching its first assertion.
#
# That happened once, to `recruitment_internship_programs`, and nothing caught
# it: the Rails suite parallelizes into per-worker databases, so the seeded one
# is only ever read by a run small enough to stay in a single process. The suite
# is green and the next `bin/rails test <one file>` is not.
#
# So the check belongs here, in the step that does the seeding, where the
# question is answerable by looking: every table holding rows afterwards must be
# a table the fixtures can empty.
namespace :seeds do
  desc "Prove every table the seeds write is one the fixtures can empty"
  task fixture_coverage: :environment do
    connection = ActiveRecord::Base.connection

    # Rails' own bookkeeping is never fixture-managed and never seeded.
    internal = %w[ schema_migrations ar_internal_metadata ]

    # A fixture file's path under test/fixtures is its table name, so a
    # namespaced table is a nested file rather than a special case.
    fixtures = Dir[Rails.root.join("test/fixtures/**/*.yml")].map do |path|
      path.sub("#{Rails.root}/test/fixtures/", "").delete_suffix(".yml")
    end

    populated = (connection.tables - internal).select do |table|
      connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(table)}").to_i.positive?
    end

    uncovered = populated - fixtures

    if uncovered.any?
      warn "Seeded tables with no fixture file to empty them:"
      uncovered.sort.each { |table| warn "  #{table}" }
      warn ""
      warn "Add test/fixtures/<table>.yml — an empty file is enough, and empty is"
      warn "what the table should be. Without one these rows survive the next"
      warn "fixture load and every test that loads fixtures fails on a foreign key."
      abort
    end

    puts "Every seeded table has a fixture file (#{populated.size} tables checked)."
  end
end
