require "application_system_test_case"

# Browser evidence for My Learning tab selection. Panel and disclosure behavior
# remain owned by their existing controllers; this only acknowledges the tab.
class MyLearningTabMotionWalkTest < ApplicationSystemTestCase
  test "My Learning tab selection settles unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit my_learning_path
    record_tab_animations

    find("[role=tab][data-panel=done]").click
    assert_selector "[role=tab][data-panel=done][aria-selected=true]"
    assert_equal [
      { "duration" => 200, "start_opacity" => 0.72,
        "start_transform" => "translateY(1px) scale(0.96)" }
    ], tab_animations
    assert_equal [
      { "duration" => 220, "start_opacity" => 0,
        "start_transform" => "translateX(12px)" }
    ], panel_animations

    find("[role=tab][data-panel=done]").click
    assert_equal 1, tab_animation_count
    assert_equal 1, panel_animation_count
  end

  test "My Learning tab selection stays still when motion is reduced" do
    sign_in_through_the_form users(:one)
    visit my_learning_path
    reduce_motion
    record_tab_animations

    find("[role=tab][data-panel=done]").click
    assert_selector "[role=tab][data-panel=done][aria-selected=true]"
    assert_empty tab_animations
    assert_empty panel_animations
  end

  private
    def record_tab_animations
      page.execute_script <<~JS
        window.__myLearningTabAnimations = []
        window.__myLearningPanelAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[role=tab][data-tab-motion]")) {
            window.__myLearningTabAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
              start_transform: keyframes[0].transform
            })
          }
          if (this.matches("[role=tabpanel][data-motion]")) {
            window.__myLearningPanelAnimations.push({
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

    def tab_animations = evaluate_script("window.__myLearningTabAnimations")
    def tab_animation_count = evaluate_script("window.__myLearningTabAnimations.length")
    def panel_animations = evaluate_script("window.__myLearningPanelAnimations")
    def panel_animation_count = evaluate_script("window.__myLearningPanelAnimations.length")
end
