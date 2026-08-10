# The flat pages in public/ are generated, not written. See lib/error_pages.rb
# for why they exist at all, and test/lib/error_pages_test.rb for the gate that
# stops them drifting from the copy.
namespace :error_pages do
  desc "Write the flat error pages in public/ from the error_pages locale copy"
  task build: :environment do
    written = ErrorPages.write_all

    puts "Wrote #{written.length} error pages: #{written.join(', ')}"
  end

  desc "Fail if the committed error pages in public/ no longer match the copy"
  task check: :environment do
    stale = ErrorPages.stale

    abort("Stale error pages: #{stale.join(', ')}. Run bin/rails error_pages:build.") if stale.any?

    puts "Error pages in public/ are current."
  end
end
