require "application_system_test_case"

# User-requested browser evidence for the lesson's JavaScript movement. The
# controller remains shared, but only lesson content panels opt in; direction
# follows the established step order and reduced-motion readers get no call to
# the Web Animations API.
class LessonPanelMotionWalkTest < ApplicationSystemTestCase
  test "lesson steps move in reading direction and bypass reduced motion" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :theory)
    record_panel_animations

    find("[role=tab][data-panel=exercise]").click
    assert_equal({ "transform" => "translateX(12px)", "duration" => 220 }, last_panel_animation)

    find("[role=tab][data-panel=theory]").click
    assert_equal({ "transform" => "translateX(-12px)", "duration" => 220 }, last_panel_animation)

    reduce_motion
    count = panel_animation_count
    find("[role=tab][data-panel=exercise]").click
    assert_equal count, panel_animation_count
    assert_selector "#lesson-panel-exercise", visible: true
  end

  private
    def record_panel_animations
      page.execute_script <<~JS
        window.__lessonPanelAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-panels-target~='panel'][data-motion]")) {
            window.__lessonPanelAnimations.push({
              transform: keyframes[0].transform,
              duration: options.duration
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

    def last_panel_animation = evaluate_script("window.__lessonPanelAnimations.at(-1)")
    def panel_animation_count = evaluate_script("window.__lessonPanelAnimations.length")
end
