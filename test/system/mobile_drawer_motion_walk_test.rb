require "application_system_test_case"

# Draft browser evidence for human QA review: the public drawer's semantic state
# precedes cancellable entrance and dismissal, while reduced motion stays still.
class MobileDrawerMotionWalkTest < ApplicationSystemTestCase
  test "the public drawer moves from the right and closes without motion when reduced" do
    visit root_path
    page.current_window.resize_to(390, 844)
    record_drawer_animations

    menu_toggle.click
    assert_selector "[data-mobile-drawer][data-state=open]:not([hidden])", visible: true
    assert_equal "true", menu_toggle["aria-expanded"]
    assert_equal "hidden", evaluate_script("document.body.style.overflow")
    assert_equal [
      { "part" => "backdrop", "duration" => 180, "start_opacity" => 0 },
      { "part" => "panel", "duration" => 240, "start_transform" => "translateX(100%)" }
    ], drawer_animations

    within "[data-mobile-drawer-panel]" do
      find("button[data-action='header#close']").click
    end
    assert_selector "[data-mobile-drawer][data-state=closed][hidden]", visible: :all
    assert_equal "false", menu_toggle["aria-expanded"]
    assert_equal "", evaluate_script("document.body.style.overflow")
    assert_equal({ "part" => "backdrop", "duration" => 140, "end_opacity" => 0 },
                 drawer_animations.third)
    assert_equal({ "part" => "panel", "duration" => 180,
                   "end_transform" => "translateX(100%)" }, drawer_animations.fourth)

    reduce_motion
    menu_toggle.click
    assert_selector "[data-mobile-drawer][data-state=open]:not([hidden])", visible: true
    assert_equal 4, drawer_animation_count

    page.send_keys(:escape)
    assert_selector "[data-mobile-drawer][data-state=closed][hidden]", visible: :all
    assert_equal 4, drawer_animation_count
  ensure
    page.current_window.resize_to(1400, 1000)
  end

  private
    def menu_toggle = find("button[data-header-target=toggle]")

    def record_drawer_animations
      page.execute_script <<~JS
        window.__drawerAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-mobile-drawer-backdrop]")) {
            const entering = keyframes[0].opacity === 0
            window.__drawerAnimations.push({
              part: "backdrop",
              duration: options.duration,
              ...(entering
                ? { start_opacity: keyframes[0].opacity }
                : { end_opacity: keyframes.at(-1).opacity })
            })
          } else if (this.matches("[data-mobile-drawer-panel]")) {
            const entering = keyframes.at(-1).transform === "none"
            window.__drawerAnimations.push({
              part: "panel",
              duration: options.duration,
              ...(entering
                ? { start_transform: keyframes[0].transform }
                : { end_transform: keyframes.at(-1).transform })
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

    def drawer_animations = evaluate_script("window.__drawerAnimations")
    def drawer_animation_count = evaluate_script("window.__drawerAnimations.length")
end
