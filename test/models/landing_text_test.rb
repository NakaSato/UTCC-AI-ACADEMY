require "test_helper"

# The copy layer's own rules. Two things are being asserted at once, because a
# card can be either kind: for a card that ships with the app a row here is an
# override and the locale files stay the source of truth, and for a card an admin
# created it is the only copy that string has.
class LandingTextTest < ActiveSupport::TestCase
  KEY = "hero.headline"

  test "an override is what the page reads, and only in the language it was written in" do
    LandingText.write(KEY, :th, "หัวข้อใหม่")

    I18n.with_locale(:th) { assert_equal("หัวข้อใหม่", Landing.copy(KEY)) }
    I18n.with_locale(:en) { assert_equal(I18n.t("landing.#{KEY}", locale: :en), Landing.copy(KEY)) }
  end

  test "clearing a field deletes the row rather than storing an empty string" do
    LandingText.write(KEY, :th, "หัวข้อใหม่")
    LandingText.write(KEY, :th, "   ")

    assert_empty(LandingText.where(key: KEY))
    I18n.with_locale(:th) { assert_equal(I18n.t("landing.#{KEY}", locale: :th), Landing.copy(KEY)) }
  end

  # Otherwise the table fills with copies of the locale files and a reworded
  # default silently stops reaching the page.
  test "a value identical to the shipped copy is not stored" do
    LandingText.write(KEY, :en, I18n.t("landing.#{KEY}", locale: :en))

    assert_empty(LandingText.where(key: KEY))
  end

  test "a key the page does not render cannot be written" do
    text = LandingText.new(key: "hero.nonesuch", locale: "th", value: "x")

    assert_not(text.valid?)
    assert_includes(text.errors.attribute_names, :key)
  end

  test "a locale the app does not have is not a locale" do
    assert_not(LandingText.new(key: KEY, locale: "*", value: "x").valid?)
  end

  test "chrome the landing editor is not about is not editable" do
    # `landing.brand_name` and `hero.logo_alt` belong to shared/_header, which is
    # on screens this editor has nothing to do with.
    assert_not_includes(Landing.editable_keys, "brand_name")
    assert_not_includes(Landing.editable_keys, "hero.logo_alt")
  end

  # ---- A card an admin added has no shipped copy to fall back to -------------

  test "a card written in one language shows that language in the other" do
    card = LandingCard.create!(collection: "topics", key: "agents_101")
    LandingText.write("#{card.prefix}.title", :th, "เอเจนต์เบื้องต้น")

    I18n.with_locale(:en) { assert_equal("เอเจนต์เบื้องต้น", Landing.copy("#{card.prefix}.title")) }
    I18n.with_locale(:th) { assert_equal("เอเจนต์เบื้องต้น", Landing.copy("#{card.prefix}.title")) }
  end

  test "a card with copy in neither language reads as blank rather than a missing translation" do
    card = LandingCard.create!(collection: "topics", key: "agents_101")

    assert_equal("", Landing.copy("#{card.prefix}.blurb"))
    assert_nil(Landing.default("#{card.prefix}.blurb"))
  end

  # The fallback must not reach past the copy the app came with, or a Thai-only
  # rewrite would displace the English the repo ships.
  test "the shipped English still wins over a Thai-only override" do
    LandingText.write(KEY, :th, "หัวข้อใหม่")

    I18n.with_locale(:en) { assert_equal(I18n.t("landing.#{KEY}", locale: :en), Landing.copy(KEY)) }
  end

  test "the request's copy of the table does not survive a write" do
    LandingText.overrides
    LandingText.write(KEY, :th, "หัวข้อใหม่")

    I18n.with_locale(:th) { assert_equal("หัวข้อใหม่", Landing.copy(KEY)) }
  end

  # Every key that ships is a real locale key, so the editor's placeholder is the
  # copy that actually ships rather than "translation missing".
  test "every shipped key resolves in both locales" do
    I18n.available_locales.each do |locale|
      Landing.editable_keys.each do |key|
        default = Landing.default(key, locale)

        assert(default.present?, "#{key} in #{locale}")
        refute_includes(default.to_s, "translation missing", "#{key} in #{locale}")
      end
    end
  end
end
