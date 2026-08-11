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

  # Render's maintenance mode answers 503 and serves a page of our choosing —
  # but the URL "must not be a URL of the service in maintenance mode", which
  # is the whole point: it is what the visitor sees when the service is off.
  # So one copy of the 503 is published to the documentation site instead, and
  # render.yaml points `maintenanceMode.uri` at it. See RB-0006.
  #
  # It cannot be the file in public/ unchanged. That one is served *by the app*
  # from the app's own origin, so its root-relative `/` and `/icon.png` resolve
  # correctly; from the docs origin they would point at the docs site, and
  # pointing them back at the app means asking a browser to fetch an icon from
  # the service that is down. The hosted copy therefore links home absolutely
  # and carries no icon at all.
  HOSTED = {
    path: Rails.root.join("docs/maintenance.html"),
    code: 503,
    home_url: "https://academy.boring9.dev/"
  }.freeze

  class << self
    # filename => rendered HTML, for every page in HttpError::STATIC_PAGES.
    def all = HttpError.static_pages.transform_values { render(it) }

    def render(page, home_url: "/", icons: true)
      ERB.new(TEMPLATE.read, trim_mode: "-")
         .result_with_hash(code: page.code, copy: copy_for(page), home_url:, icons:)
    end

    # The 503 as Render's maintenance mode serves it, from the docs origin.
    def hosted = render(HttpError.for(HOSTED[:code]), home_url: HOSTED[:home_url], icons: false)

    # Every generated page, keyed by the path it belongs at — the flat files in
    # public/ plus the hosted maintenance copy.
    def generated
      all.to_h { |filename, html| [ path_for(filename), html ] }.merge(HOSTED[:path] => hosted)
    end

    # The paths whose committed contents no longer match what the copy would
    # produce. Empty is the only passing state — see the freshness test.
    def stale
      generated.reject { |path, html| path.exist? && path.read == html }
               .keys.map { it.relative_path_from(Rails.root).to_s }
    end

    def write_all
      generated.each { |path, html| path.write(html) }
               .keys.map { it.relative_path_from(Rails.root).to_s }
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
