require "application_system_test_case"

# Browser evidence for lesson-step progress movement. The bar follows both
# forward and backward selections, does not replay the current percentage, and
# writes the destination immediately when motion is reduced.
class LessonProgressMotionWalkTest < ApplicationSystemTestCase
  test "lesson progress moves between step percentages unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :theory)
    record_progress_animations

    find("[role=tab][data-panel=code]").click
    assert_equal({ "duration" => 300,
                   "from" => "#{LessonContent.percent_for(:theory)}%",
                   "to" => "#{LessonContent.percent_for(:code)}%" },
                 last_progress_animation)

    finish_progress_animations
    find("[role=tab][data-panel=exercise]").click
    assert_equal({ "duration" => 300,
                   "from" => "#{LessonContent.percent_for(:code)}%",
                   "to" => "#{LessonContent.percent_for(:exercise)}%" },
                 last_progress_animation)

    count = progress_animation_count
    find("[role=tab][data-panel=exercise]").click
    assert_equal count, progress_animation_count

    finish_progress_animations
    reduce_motion
    find("[role=tab][data-panel=summary]").click

    assert_equal count, progress_animation_count
    assert_equal "100%", find("[data-panels-target~=progress]")[:style][/width:\s*([^;]+)/, 1]
  end

  private
    def record_progress_animations
      page.execute_script <<~JS
        window.__lessonProgressAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-panels-target~='progress']")) {
            window.__lessonProgressAnimations.push({
              duration: options.duration,
              from: keyframes[0].width,
              to: keyframes[1].width
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def finish_progress_animations
      page.execute_script <<~JS
        document.querySelector("[data-panels-target~='progress']")
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

    def last_progress_animation = evaluate_script("window.__lessonProgressAnimations.at(-1)")
    def progress_animation_count = evaluate_script("window.__lessonProgressAnimations.length")
end
