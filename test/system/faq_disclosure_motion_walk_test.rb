require "application_system_test_case"

# Draft browser evidence for human QA review: native FAQ state opens before its
# answer moves, closing cancels movement, and reduced motion stays native-only.
class FaqDisclosureMotionWalkTest < ApplicationSystemTestCase
  test "FAQ answers move after opening and remain still with reduced motion" do
    visit root_path
    record_faq_animations

    first_disclosure.find("summary").click
    assert_selector "[data-faq-disclosure][open]", count: 1
    assert_selector "[data-faq-disclosure][open] [data-faq-answer]", visible: true
    assert_equal [
      { "duration" => 190, "start_opacity" => 0.45,
        "start_transform" => "translateY(-4px)" }
    ], faq_animations

    first_disclosure.find("summary").click
    assert_no_selector "[data-faq-disclosure][open]"
    assert_equal 1, faq_animation_count

    reduce_motion
    second_disclosure.find("summary").click
    assert_selector "[data-faq-disclosure][open]", count: 1
    assert_selector "[data-faq-disclosure][open] [data-faq-answer]", visible: true
    assert_equal 1, faq_animation_count
  end

  private
    def disclosures = all("[data-faq-disclosure]")
    def first_disclosure = disclosures.first
    def second_disclosure = disclosures[1]

    def record_faq_animations
      page.execute_script <<~JS
        window.__faqAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-faq-answer]")) {
            window.__faqAnimations.push({
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

    def faq_animations = evaluate_script("window.__faqAnimations")
    def faq_animation_count = evaluate_script("window.__faqAnimations.length")
end
