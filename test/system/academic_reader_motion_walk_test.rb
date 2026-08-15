require "application_system_test_case"

# Draft browser evidence for human QA review: reader preferences apply and
# persist before the existing surface acknowledges them, while reduced motion
# keeps the same local-only state without decoration.
class AcademicReaderMotionWalkTest < ApplicationSystemTestCase
  test "reader preference changes move the surface and stay still when reduced" do
    post = AcademicPost.create!(owner: users(:one), title: "Reader motion", body: "<h2>Methods</h2><p>Safe body</p>")
    sign_in_through_the_form(users(:one))
    page.execute_script("localStorage.removeItem('academic-post-#{post.id}')")
    visit academic_post_path(post)
    record_reader_animations

    assert_selector "main[data-controller=reader][data-reader-width=comfortable][data-reader-theme=light]"
    find("select[data-action='change->reader#setWidth'] option[value=wide]").select_option
    assert_selector "main[data-controller=reader][data-reader-width=wide]"
    assert_equal [
      { "duration" => 180, "start_opacity" => 0.82,
        "start_transform" => "translateY(3px) scale(0.997)" }
    ], reader_animations
    finish_reader_animations

    reduce_motion
    find("button[data-action='reader#toggleTheme']").click
    assert_selector "main[data-controller=reader][data-reader-theme=dark]"
    assert_equal 1, reader_animation_count

    settings = JSON.parse(evaluate_script("localStorage.getItem('academic-post-#{post.id}')"))
    assert_equal "wide", settings.fetch("width")
    assert_equal "dark", settings.fetch("theme")
  end

  private
    def record_reader_animations
      page.execute_script <<~JS
        window.__readerAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-reader-target=surface]")) {
            window.__readerAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
              start_transform: keyframes[0].transform
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def finish_reader_animations
      page.execute_script <<~JS
        document.querySelector("[data-reader-target=surface]")
          .getAnimations()
          .forEach((animation) => animation.finish())
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

    def reader_animations = evaluate_script("window.__readerAnimations")
    def reader_animation_count = evaluate_script("window.__readerAnimations.length")
end
