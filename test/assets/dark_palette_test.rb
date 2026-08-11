require "test_helper"

# The dark palette is two blocks of CSS variables that must agree — one for the
# class the server writes, one for the media query that answers a visitor who
# has never chosen. Nothing at runtime notices when they drift, and the symptom
# would be a screen that looks right for someone who picked dark and wrong for
# someone whose laptop did.
#
# The contrast half is here rather than in a browser because it is arithmetic,
# and because SPEC-0023 sets WCAG 2.2 AA as the target for critical journeys.
class DarkPaletteTest < ActiveSupport::TestCase
  STYLESHEET = Rails.root.join("app/assets/tailwind/application.css")

  # The pairs a reader actually looks at, with the floor each has to clear:
  # 4.5 is AA for body text, 3.0 is AA for large text and non-text UI.
  PAIRS = [
    [ "ink", "canvas", 4.5 ], [ "ink", "surface", 4.5 ],
    [ "ink-2", "surface", 4.5 ], [ "ink-3", "surface", 4.5 ], [ "ink-4", "surface", 4.5 ],
    [ "muted", "canvas", 4.5 ], [ "muted", "surface", 4.5 ],
    # muted-2 carries meta, captions and table cells, and sits on four
    # backgrounds. surface-2 is the darkest of them and so the binding one.
    [ "muted-2", "surface", 4.5 ], [ "muted-2", "canvas", 4.5 ],
    [ "muted-2", "surface-2", 4.5 ], [ "muted-2", "surface-4", 4.5 ],
    [ "brand-ink", "canvas", 4.5 ], [ "brand-ink", "surface", 4.5 ],
    [ "brand-ink-deep", "surface", 4.5 ],
    [ "brand-ink", "brand-tint", 4.5 ],
    [ "brand-accent", "surface", 4.5 ],
    [ "success-deep", "success-tint", 4.5 ],
    [ "gold-ink", "gold-tint", 4.5 ],
    [ "on-chrome-bright", "chrome", 4.5 ], [ "on-chrome", "chrome", 4.5 ],
    [ "brand-ink", "surface", 3.0 ]
  ].freeze

  # The light palette's grey ramp is one step longer than the contrast budget
  # allows: a `muted-2` that clears AA on surface-2 needs a luminance at or
  # below 0.1507, and `muted` is already 0.1373. So these two are within 1.06x
  # of each other in light and read as one weight. Pinned, because the tempting
  # "fix" is to lighten muted-2 back into a visible step, which is exactly the
  # AA failure that was just repaired.
  RAMP_FLOOR = 1.25

  setup { @css = STYLESHEET.read }

  test "the two dark blocks define exactly the same tokens" do
    explicit, system = dark_blocks

    assert_equal explicit, system,
                 "`.dark` and the prefers-color-scheme block have drifted — " \
                 "every token must appear in both with the same value."
  end

  test "the dark blocks leave the chrome family alone" do
    # Dark mode is "the rest of the app joins the chrome". A chrome override
    # would mean the header changes too, which is the one thing it must not do.
    overridden = dark_blocks.first.keys.grep(/\A(chrome|on-chrome)/)

    assert_empty overridden, "dark mode must not redefine the chrome field"
  end

  test "every dark token also exists in the light theme" do
    unknown = dark_blocks.first.keys - light_palette.keys

    assert_empty unknown, "dark mode defines tokens the @theme block does not"
  end

  test "text meets WCAG AA against its background in both palettes" do
    { "light" => light_palette, "dark" => light_palette.merge(dark_blocks.first) }.each do |mode, palette|
      PAIRS.each do |foreground, background, floor|
        next unless palette[foreground] && palette[background]

        measured = contrast(palette[foreground], palette[background])
        assert_operator measured.round(2), :>=, floor,
                        "#{mode}: #{foreground} on #{background} is #{measured.round(2)}:1, needs #{floor}:1"
      end
    end
  end

  # 96 templates put white on a brand fill, which is why `brand` stays a fill
  # colour in dark mode and `brand-ink` exists for text — see ADR-0047.
  test "white on a brand fill meets AA in both palettes" do
    [ light_palette, light_palette.merge(dark_blocks.first) ].each do |palette|
      assert_operator contrast("#FFFFFF", palette["brand"]).round(2), :>=, 4.5
    end
  end

  # The step that light mode cannot afford, dark mode can — its surfaces are
  # dark enough to leave room below `muted`.
  test "dark keeps a visible step between the two supporting greys" do
    dark = light_palette.merge(dark_blocks.first)

    assert_operator contrast(dark["muted-2"], dark["muted"]), :>=, RAMP_FLOOR,
                    "the dark palette's muted and muted-2 have collapsed into one weight"
  end

  private
    def light_palette
      @light_palette ||= @css[/@theme\s*\{(.+?)\n\}/m, 1].scan(/--color-([a-z0-9-]+):\s*(#\h{6})/).to_h
    end

    # [the `.dark` rule's tokens, the media query's tokens]
    def dark_blocks
      @dark_blocks ||= begin
        explicit = @css[/^\s*\.dark\s*\{(.+?)\n  \}/m, 1]
        system   = @css[/:root:not\(\.light\)\s*\{(.+?)\n    \}/m, 1]

        assert explicit, "no `.dark` block found in #{STYLESHEET}"
        assert system, "no prefers-color-scheme block found in #{STYLESHEET}"

        [ explicit, system ].map { it.scan(/--color-([a-z0-9-]+):\s*(#\h{6})/).to_h }
      end
    end

    def contrast(one, other)
      a, b = luminance(one), luminance(other)
      (([ a, b ].max) + 0.05) / (([ a, b ].min) + 0.05)
    end

    def luminance(hex)
      channels = [ 1, 3, 5 ].map do |offset|
        value = hex[offset, 2].to_i(16) / 255.0
        value <= 0.04045 ? value / 12.92 : (((value + 0.055) / 1.055)**2.4)
      end

      0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    end
end
