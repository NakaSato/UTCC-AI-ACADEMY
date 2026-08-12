require "test_helper"

# `style-src` carries `unsafe-inline`, and the policy explains why: every inline
# style in this application is a number Ruby worked out — a progress bar's width,
# a stagger delay, a toast's entry offset, one background-image URL — and CSP has
# no nonce mechanism for style *attributes*, only for `<style>` elements. So the
# alternative is not a stricter policy, it is a broken layout.
#
# That argument is only true while it stays true. One static attribute —
# `style="animation-delay: 60ms"` on the catalogue subtitle — was already sitting
# in a template that a utility class could have expressed, and nothing would have
# noticed a second, or a tenth. Each one weakens the sentence the security
# decision rests on, and none of them looks like a security change when written.
#
# So the rule is asserted rather than described: an inline style may exist, and
# it must contain a value the server computed.
class InlineStyleBoundaryTest < ActiveSupport::TestCase
  TEMPLATES = Rails.root.glob("app/views/**/*.erb").freeze
  INLINE_STYLE = /style="([^"]*)"/

  test "every inline style carries a value Ruby computed" do
    static = TEMPLATES.flat_map do |template|
      template.read.scan(INLINE_STYLE).filter_map do |(declaration)|
        next if declaration.include?("<%")

        "#{template.relative_path_from(Rails.root)}: style=\"#{declaration}\""
      end
    end

    assert_empty static, <<~MESSAGE
      #{static.length} inline style(s) hold no computed value, so a utility class
      could express them. Every one of these weakens the reason `style-src`
      carries `unsafe-inline` — see config/initializers/content_security_policy.rb.

      Tailwind takes arbitrary properties: `[animation-delay:60ms]`.

      #{static.join("\n")}
    MESSAGE
  end

  # The other half, so the rule cannot be satisfied by deleting the feature: the
  # computed ones are real and are supposed to stay.
  test "the computed inline styles are still there" do
    computed = TEMPLATES.sum { it.read.scan(INLINE_STYLE).count { |(value)| value.include?("<%") } }

    assert_operator computed, :>, 20,
      "the inline styles this policy exists for have gone; if that is deliberate, " \
      "`unsafe-inline` can come out of style-src and this file can go with it"
  end
end
