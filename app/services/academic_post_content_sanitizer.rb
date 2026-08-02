class AcademicPostContentSanitizer
  ALLOWED_TAGS = %w[
    a blockquote br code div em h1 h2 h3 h4 h5 h6 hr img li ol p pre span strong
    sub sup u ul
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    alt data-citation-key data-latex data-reference-key data-type href rel src target title
  ].freeze

  def self.sanitize(html)
    new.sanitize(html)
  end

  def sanitize(html)
    sanitized = Rails::HTML5::SafeListSanitizer.new.sanitize(
      html.to_s,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )

    fragment = Loofah.html5_fragment(sanitized)
    fragment.css("img").each do |image|
      image.remove unless approved_picture_src?(image["src"])
    end
    fragment.to_html
  end

  private
    def approved_picture_src?(src)
      src.to_s.start_with?("/rails/active_storage/")
    end
end
