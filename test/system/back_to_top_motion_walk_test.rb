require "application_system_test_case"

# Draft browser evidence for human QA review: the shared back-to-top control
# moves only after its visibility threshold changes, while reduced motion stays
# immediate and animation-free.
class BackToTopMotionWalkTest < ApplicationSystemTestCase
  test "the back-to-top control moves at its threshold and stays still when reduced" do
    visit root_path
    record_back_to_top_animations

    cross_threshold(500)
    assert_selector "[data-controller=to-top][data-visible=true]", visible: true
    assert_equal [
      { "duration" => 200, "start_opacity" => 0,
        "start_transform" => "translateY(8px) scale(0.94)",
        "end_opacity" => 1 }
    ], back_to_top_animations

    cross_threshold(0)
    assert_selector "[data-controller=to-top][data-visible=false]", visible: :all
    assert_equal({ "duration" => 150, "end_opacity" => 0,
                   "end_transform" => "translateY(8px) scale(0.94)" },
                 back_to_top_animations.second)

    reduce_motion
    cross_threshold(500)
    assert_selector "[data-controller=to-top][data-visible=true]", visible: true
    assert_equal 2, back_to_top_animation_count

    cross_threshold(0)
    assert_selector "[data-controller=to-top][data-visible=false]", visible: :all
    assert_equal 2, back_to_top_animation_count
  end

  private
    def cross_threshold(top)
      page.execute_script("window.scrollTo(0, #{top}); window.dispatchEvent(new Event('scroll'))")
    end

    def record_back_to_top_animations
      page.execute_script <<~JS
        window.__backToTopAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-controller=to-top]")) {
            window.__backToTopAnimations.push({
              duration: options.duration,
              ...(keyframes.at(-1).opacity === 1
                ? {
                    start_opacity: keyframes[0].opacity,
                    start_transform: keyframes[0].transform,
                    end_opacity: keyframes.at(-1).opacity
                  }
                : {
                    end_opacity: keyframes.at(-1).opacity,
                    end_transform: keyframes.at(-1).transform
                  })
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

    def back_to_top_animations = evaluate_script("window.__backToTopAnimations")
    def back_to_top_animation_count = evaluate_script("window.__backToTopAnimations.length")
end
