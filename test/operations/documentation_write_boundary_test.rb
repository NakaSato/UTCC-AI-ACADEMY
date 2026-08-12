require "test_helper"

# ADR-0049 decision 7: no proposal writes to `docs/` or `docs/backlog.json`
# automatically. The reasoning is that the backlog is the source of truth for
# delivery and its updates carry recorded human approval, so a queue that can
# append to it is a queue that can approve work — and roadmap §15 decision 8
# asks precisely how proposals link to the roadmap, backlog, decisions, specs,
# and releases. The answer is a reference a human records.
#
# The ADR's own fitness function says this is "enforced by the absence of any
# write path from application code to `docs/` or `docs/backlog.json`, which no
# test asserts today". This is that test. It is written for the class rather
# than for proposals: the property worth holding is that nothing a request can
# reach writes a file at all, which is stronger than any per-feature check and
# does not need revisiting when the triage screen arrives.
#
# It scans `app/` and `lib/` — what a request can reach. `script/` is operator
# tooling a person runs, and `db/` seeds a database rather than a document.
class DocumentationWriteBoundaryTest < ActiveSupport::TestCase
  # Filesystem writes, and the ways out to a shell that could perform one.
  # `.write(` is only counted on a lowercase receiver: `path.write(html)` is a
  # file, `LandingText.write(key, locale, value)` is a database row, and the
  # difference between them is the whole point of this test.
  WRITE = /
    \bFile\.(write|binwrite|open|delete|unlink|rename|truncate)\b
    | \bIO\.(write|binwrite)\b
    | \bFileUtils\b
    | \bDir\.(mkdir|mktmpdir)\b
    | \b[a-z_][a-zA-Z0-9_]*\.(write|binwrite|append|mkpath|rmtree)\(
    | \bsystem\(
    | %x[({\[]
  /x

  SOURCES = Rails.root.glob("{app,lib}/**/*.{rb,erb,rake}").freeze

  # Every file that may write, and what it writes. A new entry here should be a
  # deliberate sentence: it is the list of ways this repository can rewrite its
  # own record of itself.
  WRITERS = {
    "lib/error_pages.rb" =>
      "renders the static error pages — public/*.html plus the one hosted 503 the docs site serves for " \
      "Render's maintenance mode, which is the single generated file under docs/ (RB-0006)",
    "lib/tasks/spec.rake" =>
      "shells out to run a specification's own tests; it writes nothing and reads the spec's enforced_by"
  }.freeze

  test "nothing the application can reach writes a file, except the writers named here" do
    unexpected = SOURCES.flat_map do |file|
      relative = file.relative_path_from(Rails.root).to_s
      next [] if WRITERS.key?(relative)

      file.readlines.each_with_index.filter_map do |line, index|
        next if line.match?(/\A\s*(#|<%#)/)

        "#{relative}:#{index + 1}  #{line.strip}" if line.match?(WRITE)
      end
    end

    assert_empty unexpected, <<~MESSAGE
      These write a file, or reach a shell that could, and are not in WRITERS:

      #{unexpected.join("\n")}

      Application code has no reason to write to disk. If one of these genuinely
      must, add it to WRITERS with the sentence saying what it writes — and if
      what it writes is under docs/, ADR-0049 decision 7 is the thing to read
      before adding it.
    MESSAGE
  end

  # An exception nobody needs any more is an exception that stops being read.
  test "every named writer still writes something" do
    stale = WRITERS.keys.reject do |relative|
      path = Rails.root.join(relative)
      path.exist? && path.readlines.any? { |line| !line.match?(/\A\s*(#|<%#)/) && line.match?(WRITE) }
    end

    assert_empty stale, "these no longer write anything and can leave WRITERS: #{stale.join(', ')}"
  end

  # The static scan says only one file writes under docs/. This says what it
  # writes, from the code rather than from a grep: one generated error page, and
  # nothing that anybody wrote by hand.
  test "the one generator writes a single file under docs/, and it is not a document" do
    generated = ErrorPages.generated.keys.map { |path| path.relative_path_from(Rails.root).to_s }
    under_docs = generated.select { |path| path.start_with?("docs/") }

    assert_equal [ "docs/maintenance.html" ], under_docs,
                 "the generated set has grown a second file under docs/: #{under_docs.join(', ')}"
    assert (generated - under_docs).all? { |path| path.start_with?("public/") },
           "everything else generated belongs in public/: #{generated - under_docs}"
  end

  test "no governing document is inside the set of files any code generates" do
    generated = ErrorPages.generated.keys.to_set
    governing = Rails.root.glob("docs/**/*.md") + [ Rails.root.join("docs/backlog.json") ]
    writable = governing.select { |path| generated.include?(path) }

    assert_empty writable, <<~MESSAGE
      #{writable.length} document(s) the project answers to are inside the set of
      files code generates. The backlog records delivery and its updates carry
      recorded human approval; a specification and a decision are accepted by a
      person. None of them may be produced by a program:

      #{writable.map { |path| path.relative_path_from(Rails.root).to_s }.join("\n")}
    MESSAGE
  end
end
