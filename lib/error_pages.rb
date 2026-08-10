# The flat error pages in public/, and the one place that writes them.
#
# These are the fallback under ErrorsController, and they exist because the live
# pages cannot cover every failure. Rails serves them when a request fails
# before the router can run — a bad Host header, a boot that never finished —
# and the proxy in front of the app serves them when there is no app to ask,
# which is the only way 502, 503 and 504 ever reach anyone.
#
# Two consequences follow from being flat files, and both shape the template:
# they cannot negotiate a language, so they print Thai and English together;
# and they cannot reach the asset pipeline, so every rule is inline. Nothing
# here loads from the app — a page reporting that the app is down must not need
# it.
#
# `bin/rails error_pages:build` writes them; `error_pages:check` fails if what
# is committed no longer matches the copy, which is what keeps them from
# drifting away from the live pages a year after anyone last looked.
module ErrorPages
  TEMPLATE = Rails.root.join("lib/templates/error_page.html.erb")
  DESTINATION = Rails.root.join("public")

  # Thai first, as the app is. A visitor reads whichever of the two they have.
  LOCALES = %i[ th en ].freeze

  class << self
    # filename => rendered HTML, for every page in HttpError::STATIC_PAGES.
    def all = HttpError.static_pages.transform_values { render(it) }

    def render(page)
      ERB.new(TEMPLATE.read, trim_mode: "-")
         .result_with_hash(code: page.code, copy: copy_for(page))
    end

    # The filenames whose committed contents no longer match what the copy would
    # produce. Empty is the only passing state — see the freshness test.
    def stale
      all.reject { |filename, html| path_for(filename).exist? && path_for(filename).read == html }
         .keys
    end

    def write_all
      all.each { |filename, html| path_for(filename).write(html) }.keys
    end

    def path_for(filename) = DESTINATION.join(filename)

    private
      # Pre-escaped, because the template is plain ERB with no view context to
      # escape for it, and the copy is translator-editable text.
      def copy_for(page)
        LOCALES.index_with do |locale|
          I18n.with_locale(locale) do
            {
              name: page.name, title: page.title, body: page.body,
              home: I18n.t("error_pages.home"), footer: I18n.t("error_pages.footer")
            }.transform_values { ERB::Util.html_escape(it) }
          end
        end
      end
  end
end
