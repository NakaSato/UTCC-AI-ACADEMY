require "application_system_test_case"

# Draft browser evidence for human QA review: table-of-contents selection keeps
# native anchor navigation while acknowledging a newly selected section link.
class AcademicReaderTocMotionWalkTest < ApplicationSystemTestCase
  test "table of contents acknowledges new selections and stays still when reduced" do
    post = AcademicPost.create!(owner: users(:one), title: "Contents motion", body: "<h2>Methods</h2><p>First</p><h2>Results</h2><p>Second</p>")
    sign_in_through_the_form(users(:one))
    visit academic_post_path(post)
    record_toc_animations

    assert_selector "a[data-reader-toc-link][href='#academic-section-1']"
    click_link "Methods"
    assert_equal [
      { "duration" => 160, "start_opacity" => 0.68,
        "start_transform" => "translateX(3px)" }
    ], toc_animations
    click_link "Methods"
    assert_equal 1, toc_animation_count

    reduce_motion
    click_link "Results"
    assert_equal 1, toc_animation_count
    assert_equal academic_post_path(post), page.current_path
    assert_equal "Results", evaluate_script("document.querySelector('#academic-section-2').textContent")
  end

  private
    def record_toc_animations
      page.execute_script <<~JS
        window.__readerTocAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-reader-toc-link]")) {
            window.__readerTocAnimations.push({
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

    def toc_animations = evaluate_script("window.__readerTocAnimations")
    def toc_animation_count = evaluate_script("window.__readerTocAnimations.length")
end
