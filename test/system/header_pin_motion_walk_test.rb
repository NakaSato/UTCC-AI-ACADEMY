require "application_system_test_case"

# Draft browser evidence for human QA review: the public header commits its
# pinned state before softening the shadow change, while reduced motion stays
# immediate and animation-free.
class HeaderPinMotionWalkTest < ApplicationSystemTestCase
  test "the public header softens pin changes and stays still when reduced" do
    visit root_path
    record_header_animations

    assert_selector "header[data-controller=header][data-pinned=false]", visible: true
    assert_empty header_animations

    cross_pin_threshold(50)
    assert_selector "header[data-controller=header][data-pinned=true]", visible: true
    assert_equal 200, header_animations.first.fetch("duration")
    assert_equal "none", header_animations.first.fetch("start_shadow")
    refute_equal "none", header_animations.first.fetch("end_shadow")
    finish_header_animations

    cross_pin_threshold(0)
    assert_selector "header[data-controller=header][data-pinned=false]", visible: true
    assert_equal 150, header_animations.second.fetch("duration")
    refute_equal "none", header_animations.second.fetch("start_shadow")
    assert_equal "none", header_animations.second.fetch("end_shadow")
    finish_header_animations

    reduce_motion
    cross_pin_threshold(50)
    assert_selector "header[data-controller=header][data-pinned=true]", visible: true
    assert_equal 2, header_animation_count

    cross_pin_threshold(0)
    assert_selector "header[data-controller=header][data-pinned=false]", visible: true
    assert_equal 2, header_animation_count
  end

  private
    def cross_pin_threshold(top)
      page.execute_script("window.scrollTo(0, #{top}); window.dispatchEvent(new Event('scroll'))")
    end

    def finish_header_animations
      page.execute_script <<~JS
        document.querySelector("header[data-controller=header]")
          .getAnimations()
          .forEach((animation) => animation.finish())
      JS
    end

    def record_header_animations
      page.execute_script <<~JS
        window.__headerAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("header[data-controller=header]")) {
            window.__headerAnimations.push({
              duration: options.duration,
              start_shadow: keyframes[0].boxShadow,
              end_shadow: keyframes.at(-1).boxShadow
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

    def header_animations = evaluate_script("window.__headerAnimations")
    def header_animation_count = evaluate_script("window.__headerAnimations.length")
end
