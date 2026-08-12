ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# The Vue island bundle, built once here — in the parent process, before
# `parallelize` forks anything.
#
# Vite's `autoBuild` builds on the first request for an asset, which in a
# parallel suite is eight processes discovering a stale bundle at the same
# moment: several build concurrently, and one reads `public/vite-test` while
# another is part-way through rewriting it. The symptom is a template error —
# "Vite Ruby can't find entrypoints/islands.js in the manifests" — on whichever
# handful of tests happened to render a layout during the window, which reads
# like a flake and is not one. It cost a green run and two red ones to see.
#
# So `autoBuild` is off in test (config/vite.json) and the build happens here,
# once, before there is anyone to race with. Every worker inherits a manifest
# that is already correct.
ViteRuby.commands.build || abort("vite build failed; run bin/vite build to see why")

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
