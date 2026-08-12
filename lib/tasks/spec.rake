# Run the tests a specification says enforce it.
#
# docs/test-strategy.md asks for the feature's own tests while building and the
# whole suite at the gate. The files for a feature are already recorded — every
# accepted specification lists them in `enforced_by` — so this reads that list
# rather than asking anyone to keep a second copy of it in their head.
namespace :test do
  desc "Run the tests a spec's enforced_by names: bin/rails test:spec[SPEC-0041]"
  task :spec, [ :id ] do |_task, args|
    require "yaml"

    id = args[:id].to_s.strip.upcase
    abort("Usage: bin/rails test:spec[SPEC-0041]") if id.empty?

    documents = Dir[Rails.root.join("docs/{specs,decisions}/*.md")].filter_map do |path|
      frontmatter = File.read(path)[/\A---\n(.*?)\n---\n/m, 1]
      metadata = frontmatter && YAML.safe_load(frontmatter, permitted_classes: [ Date ])
      [ path, metadata ] if metadata.is_a?(Hash) && metadata["id"].to_s.upcase == id
    end

    path, metadata = documents.first
    abort("No lifecycle document has id #{id}.") if path.nil?

    files = Array(metadata["enforced_by"]).select { it.to_s.start_with?("test/") }
    if files.empty?
      abort("#{id} names no test files in enforced_by. Add them there first — that list is " \
            "what makes a feature-scoped run possible.")
    end

    missing = files.reject { Rails.root.join(it).exist? }
    abort("#{id} names files that do not exist: #{missing.join(', ')}") if missing.any?

    # System tests need their own runner, and they are the slow half — so they
    # are named rather than run, and the gate stays where it is.
    system_tests, rails_tests = files.partition { it.start_with?("test/system/") }

    puts "#{id}: #{File.basename(path)}"
    puts "Running #{rails_tests.length} test files"
    if system_tests.any?
      puts "Not run here (bin/rails test:system, or bin/verify): #{system_tests.join(', ')}"
    end
    puts

    abort("#{id} names only system tests. Run bin/rails test:system.") if rails_tests.empty?

    # A subprocess rather than Rake::Task["test"].invoke: the Rails test task
    # takes its files from the command line, not from arguments, so invoking it
    # in-process quietly runs the whole suite — which is the one thing this task
    # exists to avoid.
    command = [ "bin/rails", "test", *rails_tests ]
    puts command.join(" ")
    abort("#{id} is failing.") unless system(*command)
  end
end
