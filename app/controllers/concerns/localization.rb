# Which language a request answers in. Extracted from ApplicationController so
# ErrorsController can pick a locale without inheriting the rest of the stack:
# an error page has to render when the session store, and the database under it,
# are the thing that failed.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    helper_method :theme_class
  end

  private
    # What goes on <html>. Nothing when the visitor has never chosen, which is
    # what hands the decision to `prefers-color-scheme` in the stylesheet — the
    # same fall-through `switch_locale` gives Accept-Language. An explicit
    # "light" is a class rather than an absence because it has to beat a dark
    # system setting.
    # Not an endless def with a modifier `if`: that would make the *definition*
    # conditional and evaluate `session` while the class is loading.
    def theme_class
      session[:theme] if %w[ light dark ].include?(session[:theme])
    end

    # Three sources, most specific first: the URL, the toggle, then the browser.
    #
    # The header's toggle writes session[:locale] and every request reads it back.
    # A visitor who has never touched it — which is every crawler, and every
    # student on their first request — used to get Thai regardless of what they
    # asked for; now the Accept-Language header decides, and Thai is only the
    # answer when nothing else matches.
    def switch_locale(&)
      I18n.with_locale(requested_locale || session[:locale] || negotiated_locale, &)
    end

    # `?lang=` overrides both, and deliberately does *not* persist. It exists so
    # each language has a URL of its own to be linked, canonicalised and paired
    # in an hreflang — see ApplicationHelper#locale_url. Writing the session here
    # is what the toggle is POST to avoid: Turbo prefetches links on hover, and a
    # param that stuck would change a visitor's language by being pointed at.
    def requested_locale = I18n.available_locales.find { it.to_s == params[:lang] }

    # Quality-ordered, matched on the primary subtag, so `th-TH` answers Thai and
    # `en-GB` English. An unparsable or absent header leaves the default.
    def negotiated_locale
      ranked = request.headers["Accept-Language"].to_s.split(",").filter_map do |part|
        tag, quality = part.split(";q=")
        [ tag.strip.split("-").first.downcase, (quality || 1).to_f ] if tag.present?
      end

      ranked.sort_by.with_index { |(_, quality), index| [ -quality, index ] }
            .filter_map { |tag, _| I18n.available_locales.find { it.to_s == tag } }
            .first || I18n.default_locale
    end
end
