require "application_system_test_case"

# Browser evidence that only a newly recorded integrity row moves. Rows rebuilt
# from durable events and older rows stay still; reduced motion and inactive
# steps retain the same log state without invoking Web Animations.
class IntegrityLogMotionWalkTest < ApplicationSystemTestCase
  test "only the newest assessed-step incident row settles in" do
    ProctorEvent.create!(user: users(:one), course: courses(:ai1101), topic: topics(:topic_1_1),
                         kind: "menu", occurred_at: Time.current)
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)

    assert_selector "[data-integrity-event-row]", count: 1
    record_log_animations
    assert_equal 0, log_animation_count

    trigger_context_menu
    assert_selector "[data-integrity-event-row]", count: 2
    assert_equal({ "duration" => 260, "start" => "translateX(-6px)", "weight" => "low" },
                 last_log_animation)

    trigger_context_menu
    assert_selector "[data-integrity-event-row]", count: 3
    assert_equal 2, log_animation_count

    reduce_motion
    trigger_context_menu
    assert_selector "[data-integrity-event-row]", count: 4
    assert_equal 2, log_animation_count

    find("[role=tab][data-panel=theory]").click
    trigger_context_menu
    assert_selector "[data-integrity-event-row]", count: 4, visible: :all
    assert_equal 2, log_animation_count
  end

  private
    def trigger_context_menu
      page.execute_script <<~JS
        document.querySelector("main#main").dispatchEvent(
          new MouseEvent("contextmenu", { bubbles: true, cancelable: true })
        )
      JS
    end

    def record_log_animations
      page.execute_script <<~JS
        window.__integrityLogAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-integrity-event-row]")) {
            window.__integrityLogAnimations.push({
              duration: options.duration,
              start: keyframes[0].transform,
              weight: this.dataset.weight
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

    def last_log_animation = evaluate_script("window.__integrityLogAnimations.at(-1)")
    def log_animation_count = evaluate_script("window.__integrityLogAnimations.length")
end
