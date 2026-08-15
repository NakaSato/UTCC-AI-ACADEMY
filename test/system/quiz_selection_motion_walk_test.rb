require "application_system_test_case"

# Browser evidence for the exercise answer marker's selection acknowledgement.
# Radio semantics update before decoration, and repeated or reduced-motion
# selections retain the same state without invoking Web Animations.
class QuizSelectionMotionWalkTest < ApplicationSystemTestCase
  test "new answer markers settle once unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_selection_animations

    option(1).click
    assert_equal "true", option(1)["aria-checked"]
    assert_equal({ "duration" => 200, "index" => "1", "peak" => "scale(1.12)",
                   "start" => "scale(0.86)" }, last_selection_animation)

    count = selection_animation_count
    option(1).click
    assert_equal count, selection_animation_count

    option(2).click
    assert_equal "false", option(1)["aria-checked"]
    assert_equal "true", option(2)["aria-checked"]
    assert_equal "2", last_selection_animation.fetch("index")

    reduce_motion
    count = selection_animation_count
    option(3).click
    assert_equal "true", option(3)["aria-checked"]
    assert_equal count, selection_animation_count
  end

  private
    def option(index) = find("[data-quiz-target~=option][data-index='#{index}']")

    def record_selection_animations
      page.execute_script <<~JS
        window.__quizSelectionAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-quiz-choice-indicator]")) {
            window.__quizSelectionAnimations.push({
              duration: options.duration,
              index: this.dataset.quizChoiceIndicator,
              peak: keyframes[1].transform,
              start: keyframes[0].transform
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

    def last_selection_animation = evaluate_script("window.__quizSelectionAnimations.at(-1)")
    def selection_animation_count = evaluate_script("window.__quizSelectionAnimations.length")
end
