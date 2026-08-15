require "application_system_test_case"

# Draft browser evidence for human QA review: choosing a public track level
# commits the tab and filtered cards before one cancellable entrance sequence.
class TrackFilterMotionWalkTest < ApplicationSystemTestCase
  test "track filters move matching cards once and respect reduced motion" do
    visit root_path
    record_track_animations

    select_level("beginner")
    assert_selected_level("beginner")
    assert_visible_levels([ "beginner" ])
    assert_equal [
      { "duration" => 220, "delay" => 0,
        "start_transform" => "translateY(6px) scale(0.985)" },
      { "duration" => 220, "delay" => 35,
        "start_transform" => "translateY(6px) scale(0.985)" }
    ], track_animations

    select_level("intermediate")
    assert_selected_level("intermediate")
    assert_visible_levels([ "intermediate" ])
    assert_equal 4, track_animation_count

    select_level("intermediate")
    assert_equal 4, track_animation_count

    reduce_motion
    select_level("advanced")
    assert_selected_level("advanced")
    assert_visible_levels([ "advanced" ])
    assert_equal 4, track_animation_count
  end

  private
    def select_level(level)
      find("[role=tab][data-level='#{level}']").click
    end

    def assert_selected_level(level)
      assert_selector "[role=tab][data-level='#{level}'][aria-selected=true]"
      assert_selector "[role=tab][aria-selected=false]", count: Landing.track_filters.size - 1
    end

    def assert_visible_levels(levels)
      assert_selector "[data-track-card]:not([hidden])", count: Landing.tracks.count { levels.include?(it.level.to_s) }
      all("[data-track-card]:not([hidden])").each { assert_includes levels, it["data-level"] }
    end

    def record_track_animations
      page.execute_script <<~JS
        window.__trackAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-track-card]")) {
            window.__trackAnimations.push({
              duration: options.duration,
              delay: options.delay,
              start_transform: keyframes[0].transform
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def reduce_motion
      page.execute_script <<~JS
        window.matchMedia = (query) => ({
          matches: query === "(prefers-reduced-motion: reduce)",
          media: query,
          addEventListener() {},
          removeEventListener() {}
        })
      JS
    end

    def track_animations = evaluate_script("window.__trackAnimations")
    def track_animation_count = evaluate_script("window.__trackAnimations.length")
end
