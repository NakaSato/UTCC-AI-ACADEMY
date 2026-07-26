# The JSON-LD a page publishes. Schema.org vocabulary lives here rather than in
# the content modules: `Landing` describes the site to the app, this describes the
# same values to a crawler, and neither has to learn the other's shape.
#
# Every document is built from the reader methods the views already call, so copy
# is translated once and the structured data follows the locale the page rendered
# in — a Thai page ships Thai answers.
module SchemaHelper
  # `raw` because the tag helper would escape the braces into uselessness, and
  # `json_escape` because the one thing that must never survive into a <script>
  # is a closing tag. A nil document renders nothing, so a page can offer a
  # section that has nothing to say without guarding at the call site.
  def json_ld(document)
    return if document.blank?

    tag.script raw(json_escape(JSON.pretty_generate(document))), type: "application/ld+json"
  end

  # Documents that name the school point at this id instead of repeating the
  # address, which is written once in shared/_meta.
  def organization_id = "#{request.base_url}#organization"

  def organization_ref = { "@id" => organization_id }

  def faq_schema(questions)
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => questions.map do |question|
        {
          "@type" => "Question",
          "name" => question.question,
          "acceptedAnswer" => { "@type" => "Answer", "text" => question.answer }
        }
      end
    }
  end

  # Lists rather than loose nodes: the tracks and the events are both ordered on
  # screen, and order is the one thing a flat set would lose. Each carries the
  # name of the section it came from, which is also what tells two ItemLists on
  # the same page apart.
  # A collection an admin has emptied has nothing to list, and an ItemList with
  # no items is a claim about nothing rather than a shorter claim.
  def course_list_schema(tracks, url:)
    item_list Landing.copy("tracks.title"), tracks.map { course_schema(it, url:) } if tracks.any?
  end

  # Only the events that happen on a day. A recurring "every Wednesday" has no
  # startDate to give, and Event without one is invalid rather than vague.
  def event_list_schema(events, url:)
    dated = events.select(&:dated?)

    item_list Landing.copy("events.title"), dated.map { event_schema(it, url:) } if dated.any?
  end

  private
    def item_list(name, items)
      {
        "@context" => "https://schema.org",
        "@type" => "ItemList",
        "name" => name,
        "itemListElement" => items.each_with_index.map do |item, index|
          { "@type" => "ListItem", "position" => index + 1, "item" => item }
        end
      }
    end

    # No `offers`: the tracks carry no price in the app, and inventing a free one
    # to earn a richer result would be a claim this codebase cannot back.
    def course_schema(track, url:)
      {
        "@type" => "Course",
        "name" => track.title,
        "description" => track.blurb,
        "url" => url,
        "provider" => organization_ref,
        "educationalLevel" => track.level_label,
        "inLanguage" => I18n.available_locales.map(&:to_s),
        # Weeks as an ISO 8601 duration; an open-ended track simply omits it.
        "timeRequired" => (track.weeks ? "P#{track.weeks}W" : nil)
      }.compact
    end

    # The date only. The copy says what time it starts, in words and in two
    # calendars, and neither of those is a time this can publish.
    def event_schema(event, url:)
      {
        "@type" => "Event",
        "name" => event.title,
        "startDate" => event.starts_on,
        "location" => { "@type" => "Place", "name" => event.where_label },
        "organizer" => organization_ref,
        "url" => url
      }
    end
end
