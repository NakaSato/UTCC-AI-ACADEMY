require "test_helper"

# The island bundle Vite builds, and the property everything else rests on
# (ADR-0053).
#
# Vue has two builds. The full one carries a template compiler and turns
# `<template>` into render code with `Function(…)` **in the browser** — which
# this application's CSP blocks (`script-src 'self'`, no `unsafe-eval`). The
# runtime one cannot compile anything and does not need to, because Vite
# compiled the components at build time.
#
# Single-file components therefore only work here as long as the compiler stays
# in the toolchain. `vite.config.mts` aliasing `vue` to the full build, or a
# component built with a runtime `template:` string, would put it back — and the
# failure is invisible where it matters: it renders in a dev server that has no
# policy loaded, and silently does nothing in production. So this asserts the
# emitted bytes rather than the intent.
class VueBuildTest < ActiveSupport::TestCase
  ROOT = Rails.root
  FRONTEND = ROOT.join("app/frontend")

  # Cheap enough to do rather than assume: the whole bundle builds in well under
  # a second, and asserting a build somebody else made is asserting nothing.
  def bundle
    @@bundle ||= begin
      assert ViteRuby.commands.build, "vite build failed; run bin/vite build to see why"
      output = ViteRuby.config.build_output_dir
      files = Dir.glob(output.join("assets/islands-*.js"))

      assert_equal 1, files.length, "expected one islands bundle in #{output}, found #{files.inspect}"
      File.read(files.first)
    end
  end

  test "the shipped bundle carries no template compiler" do
    message = "the island bundle contains Vue's template compiler, which this application's CSP " \
              "blocks. Check vite.config.mts for an alias to vue/dist/vue.esm-bundler, and check " \
              "no island uses a runtime `template:` string. See ADR-0053."

    assert_no_match(/\bnew Function\s*\(/, bundle, message)
    assert_no_match(/compileToFunction/, bundle, message)
    assert_no_match(/@vue\/compiler-dom/, bundle, message)
  end

  test "the bundle is really the island layer" do
    assert_match(/data-vue-island/, bundle, "the bridge is what this entrypoint exists for")
  end

  # One bridge, and one place an app is created. A second `createApp` is an app
  # nothing unmounts when Turbo replaces the page around it.
  test "nothing mounts Vue except the island entrypoint" do
    callers = ROOT.glob("app/{frontend,javascript}/**/*.{js,vue}").select { it.read.match?(/\bcreateApp\s*\(/) }

    assert_equal [ FRONTEND.join("entrypoints/islands.js") ], callers
  end

  # A name in the registry that resolves to nothing is a console warning in
  # production and nothing on screen.
  test "the registry names components that exist" do
    entrypoint = FRONTEND.join("entrypoints/islands.js").read
    imported = entrypoint.scan(%r{^import (\w+) from "\.\./islands/([\w.]+)"$})

    assert_operator imported.length, :>, 0, "the entrypoint imports no island, so nothing can mount"

    imported.each { |_binding, file| assert_path_exists FRONTEND.join("islands/#{file}") }
    imported.each { |binding, _file| assert_match(/"[a-z-]+": #{binding}/, entrypoint, "#{binding} is imported and never registered") }
  end

  # The two toolchains are separate on purpose: import maps own Hotwire and
  # Tiptap, Vite owns the islands. Vue in both is two copies of Vue.
  test "the import map does not also carry Vue" do
    importmap = ROOT.join("config/importmap.rb").read

    assert_no_match(/^pin "vue"/, importmap)
    assert_not ROOT.join("vendor/javascript/vue.js").exist?,
      "the vendored Vue is what Vite replaced; two copies is the bug this test exists for"
  end

  # A source map is nine times the size of what it explains, and nothing here
  # consumes one: no error tracker, no upload step, and no other bundle ships a
  # map, because Propshaft serves the import map's files as they were written.
  # So production gets none, and every other mode keeps it.
  #
  # Asserted against the configuration rather than a production build, which is
  # the same shape as the importmap assertion above: this test builds in test
  # mode, where the map is deliberately present.
  test "the production build ships no source map" do
    config = ROOT.join("vite.config.mts").read

    assert_match(/sourcemap:\s*mode\s*!==\s*["']production["']/, config,
      "production would serve the island sources beside the bundle — see ADR-0053")
  end

  test "Vite builds only the island layer" do
    entrypoints = FRONTEND.glob("entrypoints/*").map { it.basename.to_s }

    assert_equal [ "islands.js" ], entrypoints,
      "a second entrypoint is a second bundle, and a decision (ADR-0053) rather than a file"
  end
end
