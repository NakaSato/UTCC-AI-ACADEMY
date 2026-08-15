require "application_system_test_case"

# Draft browser evidence for human QA review: the first enrollment stays still,
# while another learner-opened course reuses the native disclosure entrance.
class MyLearningDisclosureMotionWalkTest < ApplicationSystemTestCase
  test "My Learning course content moves only after the learner opens it" do
    start_course("AI1101")
    start_course("AI1102")
    sign_in_through_the_form users(:one)
    visit my_learning_path
    record_enrollment_animations

    assert_selector "[data-panel=progress]:not([hidden]) [data-enrollment-course]", count: 2
    assert_selector "[data-panel=progress]:not([hidden]) [data-enrollment-course][open]", count: 1
    assert_equal 0, enrollment_animation_count

    course_code = closed_enrollment["data-enrollment-course"]
    closed_enrollment.find("summary").click
    assert_selector "[data-enrollment-course='#{course_code}'][open] [data-enrollment-content]", visible: true
    assert_equal [
      { "duration" => 190, "start_opacity" => 0.45,
        "start_transform" => "translateY(-4px)" }
    ], enrollment_animations

    find("[data-enrollment-course='#{course_code}'] summary").click
    assert_no_selector "[data-enrollment-course='#{course_code}'][open]"
    assert_equal 1, enrollment_animation_count

    reduce_motion
    find("[data-enrollment-course='#{course_code}'] summary").click
    assert_selector "[data-enrollment-course='#{course_code}'][open] [data-enrollment-content]", visible: true
    assert_equal 1, enrollment_animation_count
  end

  private
    def start_course(code)
      TopicCompletion.record(user: users(:one), course_code: code,
                             topic_key: Syllabus.topic_keys(code).first, kind: :learned)
    end

    def closed_enrollment
      find("[data-panel=progress]:not([hidden]) [data-enrollment-course]:not([open])", match: :first)
    end

    def record_enrollment_animations
      page.execute_script <<~JS
        window.__enrollmentAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-enrollment-content]")) {
            window.__enrollmentAnimations.push({
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

    def enrollment_animations = evaluate_script("window.__enrollmentAnimations")
    def enrollment_animation_count = evaluate_script("window.__enrollmentAnimations.length")
end
