# The two policy documents — the privacy notice the PDPA requires, and the terms
# of use. Ruby holds only which sections a document has and in what order; every
# word is in the locale files, the same split as the rest of app/models.
#
# Sections are **keyed, not positional**: a section looks its own copy up by
# name, so adding one here without writing its copy raises a missing translation
# rather than silently shifting every heading below it.
#
# `updated_on` is a locale string rather than a formatted Date on purpose — Thai
# convention writes the Buddhist year (2569), and no strftime of a Gregorian
# date produces that.
module Policy
  SECTIONS = {
    privacy: %i[ who collected purposes basis cookies sharing retention security
                 rights complaints children changes contact ].freeze,
    terms: %i[ who eligibility account acceptable_use academic grading content
               availability liability termination changes contact ].freeze
  }.freeze

  Section = Data.define(:document, :key) do
    def title = copy("title")

    def paragraphs = copy("body")

    # Not every section has a bulleted list. `exists?` rather than a `default:`
    # because I18n reads an Array default as a list of further keys to try, so
    # `default: []` means "no default given" and hands back the missing-
    # translation string instead of an empty list.
    def items = I18n.exists?(path("items")) ? copy("items") : []

    def items? = items.any?

    private
      def path(leaf) = "#{document}.sections.#{key}.#{leaf}"

      def copy(leaf) = I18n.t(path(leaf))
  end

  class << self
    def documents = SECTIONS.keys

    def document?(name) = SECTIONS.key?(name)

    def sections_for(document) = SECTIONS.fetch(document).map { Section.new(document:, key: it) }

    def title_for(document) = I18n.t("#{document}.title")

    def intro_for(document) = I18n.t("#{document}.intro")

    def updated_on_for(document) = I18n.t("#{document}.updated_on")
  end
end
