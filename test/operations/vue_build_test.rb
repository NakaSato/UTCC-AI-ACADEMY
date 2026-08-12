require "test_helper"

# Vue is pinned as the runtime-only build, and this is what keeps it that way.
#
# `bin/importmap pin vue` fetches `vue.esm-browser.prod.js` — the full build,
# which compiles template strings into render functions with `Function(…)`. The
# CSP this application sends is `script-src 'self'` with a nonce and no
# `unsafe-eval`, so that call is blocked in every browser that honours it: an
# island written with a `template:` would render nothing in production and
# everything in a test that never loaded the policy.
#
# The failure is therefore invisible exactly where it matters, which is why it
# is asserted against the vendored bytes rather than trusted to a comment in
# `config/importmap.rb`. Re-running `bin/importmap pin vue` after an upgrade is
# the way this regresses, and this test is what catches it. ADR-0051.
class VueBuildTest < ActiveSupport::TestCase
  VENDORED = Rails.root.join("vendor/javascript/vue.js")
  IMPORTMAP = Rails.root.join("config/importmap.rb")

  test "the vendored build carries no template compiler" do
    source = VENDORED.read

    assert_no_match(/\bnew Function\s*\(/, source, compiler_message)
    assert_no_match(/[^.\w]Function\s*\(\s*`/, source, compiler_message)
    assert_no_match(/compileToFunction/, source, compiler_message)
  end

  test "the vendored build is the one the importmap points at, and is really Vue" do
    assert_match(/^pin "vue", to: "vue\.js"/, IMPORTMAP.read)
    assert_match(%r{vue\.runtime\.esm-browser\.prod\.js}, VENDORED.read.lines.first.to_s,
      "the first line records where the file came from; it must be the runtime build's URL")
    assert_match(/export\s*\{/, VENDORED.read, "an ES module is what the importmap can load")
  end

  # Every island the registry names has a file, and every island file is
  # reachable through the importmap. A name that resolves to nothing is a
  # console warning in production and nothing on screen.
  test "the registry names islands that exist" do
    registry = Rails.root.join("app/javascript/islands/registry.js").read
    named = registry.scan(/^import (\w+) from "islands\/([a-z0-9_]+)"$/)

    assert_operator named.length, :>, 0, "the registry imports nothing, so nothing can mount"

    named.each do |_binding, file|
      assert_path_exists Rails.root.join("app/javascript/islands/#{file}.js")
    end

    assert_match(/^pin_all_from "app\/javascript\/islands", under: "islands"$/, IMPORTMAP.read)
  end

  # One bridge, and the only place `createApp` is called. Vue mounted from
  # anywhere else is an app nothing unmounts when Turbo replaces the page.
  test "nothing mounts Vue except the island controller" do
    callers = Rails.root.glob("app/javascript/**/*.js").select { it.read.match?(/\bcreateApp\s*\(/) }

    assert_equal [ Rails.root.join("app/javascript/controllers/vue_island_controller.js") ], callers
  end

  private
    def compiler_message
      "vendor/javascript/vue.js is the full Vue build. It compiles templates with Function(), " \
      "which this application's CSP blocks — re-vendor vue.runtime.esm-browser.prod.js. See ADR-0051."
    end
end
