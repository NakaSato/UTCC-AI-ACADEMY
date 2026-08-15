require "application_system_test_case"

# Draft browser evidence for human QA review: the observer commits active-link
# semantics before acknowledging a newly current section, while reduced motion
# keeps the same scroll-spy state without decoration.
class ScrollSpyMotionWalkTest < ApplicationSystemTestCase
  test "the newly current public nav link moves and stays still when reduced" do
    visit root_path
    record_scroll_spy_animations

    assert_empty scroll_spy_animations
    scroll_to_section("learn")
    assert_selector "a[data-scroll-spy-link][href='#learn'][aria-current=location]", visible: true
    assert_equal [
      { "duration" => 180, "start_opacity" => 0.68,
        "start_transform" => "translateY(2px) scale(0.985)" }
    ], scroll_spy_animations
    finish_scroll_spy_animations

    scroll_to_top
    assert_no_selector "a[data-scroll-spy-link][aria-current=location]", visible: true

    reduce_motion
    scroll_to_section("learn")
    assert_selector "a[data-scroll-spy-link][href='#learn'][aria-current=location]", visible: true
    assert_equal 1, scroll_spy_animation_count
  end

  private
    def scroll_to_section(id)
      page.execute_script <<~JS
        document.documentElement.style.scrollBehavior = "auto"
        const section = document.getElementById("#{id}")
        const top = section.getBoundingClientRect().top + window.scrollY - 100
        window.scrollTo(0, top)
      JS
    end

    def scroll_to_top
      page.execute_script("document.documentElement.style.scrollBehavior = 'auto'; window.scrollTo(0, 0)")
    end

    def finish_scroll_spy_animations
      page.execute_script <<~JS
        document.querySelectorAll("a[data-scroll-spy-link]").forEach((link) => {
          link.getAnimations().forEach((animation) => animation.finish())
        })
      JS
    end

    def record_scroll_spy_animations
      page.execute_script <<~JS
        window.__scrollSpyAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("a[data-scroll-spy-link]")) {
            window.__scrollSpyAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
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

    def scroll_spy_animations = evaluate_script("window.__scrollSpyAnimations")
    def scroll_spy_animation_count = evaluate_script("window.__scrollSpyAnimations.length")
end
