require "application_system_test_case"

# Draft browser evidence for human QA review: server-selected module state is
# still, while learner-opened syllabus content uses the native disclosure cue.
class CourseModuleMotionWalkTest < ApplicationSystemTestCase
  test "syllabus modules move only after a learner opens them" do
    sign_in_through_the_form users(:one)
    visit course_path("AI1101")
    record_module_animations

    assert_selector "[data-course-module][open]", count: 1
    assert_equal 0, module_animation_count

    module_number = closed_module["data-course-module"]
    closed_module.find("summary").click
    assert_selector "[data-course-module='#{module_number}'][open] [data-course-module-content]", visible: true
    assert_equal [
      { "duration" => 190, "start_opacity" => 0.45,
        "start_transform" => "translateY(-4px)" }
    ], module_animations

    find("[data-course-module='#{module_number}'] summary").click
    assert_no_selector "[data-course-module='#{module_number}'][open]"
    assert_equal 1, module_animation_count

    reduce_motion
    find("[data-course-module='#{module_number}'] summary").click
    assert_selector "[data-course-module='#{module_number}'][open] [data-course-module-content]", visible: true
    assert_equal 1, module_animation_count
  end

  private
    def closed_module
      find("[data-course-module]:not([open])", match: :first)
    end

    def record_module_animations
      page.execute_script <<~JS
        window.__moduleAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-course-module-content]")) {
            window.__moduleAnimations.push({
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

    def module_animations = evaluate_script("window.__moduleAnimations")
    def module_animation_count = evaluate_script("window.__moduleAnimations.length")
end
