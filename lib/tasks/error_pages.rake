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

  # `check` proves the repository agrees with itself. It says nothing about what
  # a visitor meets during planned downtime, which is a page on a different
  # origin, published by a different pipeline, that Render fetches by URL. That
  # page was unreachable for three days in August 2026 while every local gate
  # passed — a failed documentation deploy leaves the previous copy online
  # looking current, and the missing page is on the one screen nobody opens
  # until they need it. This task is the only check that opens it. RB-0006.
  desc "Fail unless the maintenance page render.yaml names is live and current"
  task published: :environment do
    require "net/http"
    require "yaml"

    url = YAML.load_file(Rails.root.join("render.yaml"))
             .dig("services", 0, "maintenanceMode", "uri")
    abort("render.yaml declares no maintenanceMode.uri.") if url.blank?

    response = begin
      Net::HTTP.get_response(URI.parse(url), { "Accept" => "text/html" })
    rescue StandardError => error
      abort("#{url} could not be reached: #{error.class} — #{error.message}")
    end

    if response.is_a?(Net::HTTPRedirection)
      abort(<<~REDIRECT)
        #{url} answers #{response.code} → #{response['location']}.
        Render must not be asked to follow a hop for this page. Point
        maintenanceMode.uri at the destination, and check whether vercel.json's
        cleanUrls setting changed.
      REDIRECT
    end

    # A challenge is not a missing page, and telling the two apart is the whole
    # value of this task: on 2026-08-12 the host began answering every path with
    # its own bot checkpoint, and "check that the deploy succeeded" would have
    # sent the reader looking in the wrong place for as long as it lasted.
    if [ "401", "403" ].include?(response.code)
      abort(<<~CHALLENGED)
        #{url} answers #{response.code}#{" — #{response.body[/<title>(.*?)<\/title>/m, 1]}" if response.body.to_s.include?("<title>")}.
        The host is challenging or refusing this request rather than serving the
        page. That is a setting on the documentation host, not a failed deploy:
        check its bot protection, attack-challenge mode, and deployment
        protection. A maintenance page a visitor has to pass a challenge to read
        is not a maintenance page — see RB-0006.
      CHALLENGED
    end

    unless response.is_a?(Net::HTTPOK)
      abort(<<~MISSING)
        #{url} answers #{response.code}, so planned downtime would show Render's
        default page. The documentation site publishes this page on push to main
        — check that its last deploy succeeded rather than aborting and leaving
        the previous copy online.
      MISSING
    end

    if response.body != ErrorPages.hosted
      abort(<<~STALE)
        #{url} is live but is not the page this repository generates. The docs
        site is serving an older deploy, or the copy changed without
        bin/rails error_pages:build being run and merged.
      STALE
    end

    puts "#{url} serves the current maintenance page."
  end
end
