require "test_helper"

# The landing page used to be Thai string literals in HomeController, so the
# point of these tests is the thing that was previously impossible: that every
# card resolves in **both** locales, and that the English is real English rather
# than the Thai falling through.
class LandingTest < ActiveSupport::TestCase
  test "every card resolves its copy in both locales" do
    %i[th en].each do |locale|
      I18n.with_locale(locale) do
        Landing.topics.each do |topic|
          assert_resolved topic.title, locale
          assert_resolved topic.blurb, locale
        end

        Landing.tracks.each do |track|
          assert_resolved track.title, locale
          assert_resolved track.blurb, locale
          assert_resolved track.level_label, locale
          assert_resolved track.duration, locale
        end

        Landing.shares.each do |share|
          [ share.title, share.author, share.tag, share.date ].each { assert_resolved it, locale }
        end

        Landing.events.each do |event|
          [ event.title, event.when_label, event.where_label ].each { assert_resolved it, locale }
        end

        Landing.faqs.each do |faq|
          assert_resolved faq.question, locale
          assert_resolved faq.answer, locale
        end

        Landing.track_filters.each { assert_resolved it.label, locale }
      end
    end
  end

  # The bug this whole change fixes: if a key existed only in th.yml, the English
  # page would fall back to Thai and still "resolve". Comparing the two catches
  # that where a missing-translation check cannot.
  test "the English copy is actually translated, not the Thai falling back" do
    th = I18n.with_locale(:th) { landing_strings }
    en = I18n.with_locale(:en) { landing_strings }

    shared = th & en
    # Proper nouns and dates legitimately match across locales; prose must not.
    allowed = [ "Prompt Engineering", "Data & Machine Learning", "UTCC AI Institute" ]

    assert_equal [], shared - allowed, "these strings are identical in both locales"
  end

  test "a track with no week count reads as ongoing rather than zero weeks" do
    ongoing = Landing.tracks.find { it.weeks.nil? }

    assert ongoing, "expected one open-ended track"
    assert_equal I18n.t("landing.tracks.ongoing"), ongoing.duration
  end

  test "the level filter reuses the shared level names" do
    filters = Landing.track_filters

    assert_equal I18n.t("landing.tracks.filter_all"), filters.first.label
    assert_equal I18n.t("levels.beginner"), filters.second.label
  end

  private
    def assert_resolved(value, locale)
      assert value.present?, "empty value in #{locale}"
      refute_includes value, "translation missing", "unresolved key in #{locale}"
    end

    # Only the prose, not the taxonomy — titles, blurbs, questions and answers.
    def landing_strings
      Landing.topics.flat_map { [ it.title, it.blurb ] } +
        Landing.tracks.flat_map { [ it.title, it.blurb ] } +
        Landing.shares.flat_map { [ it.title, it.author, it.tag ] } +
        Landing.events.flat_map { [ it.title, it.when_label, it.where_label ] } +
        Landing.faqs.flat_map { [ it.question, it.answer ] }
    end
end
