class ApplicationController < ActionController::Base
  include Authentication
  # After Authentication, so `require_authentication` runs first and a signed-out
  # visitor still lands on /login rather than the catalog.
  include Authorization
  before_action :set_observability_context
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  # The header's gem and streak counters sit on every signed-in screen, so this
  # is a helper rather than something each controller has to assign. The bell is
  # there for the same reason, and is also what names the channel it listens on.
  helper_method :progress, :notification_bell

  private
    def set_observability_context
      Current.request_id = request.request_id
    end

    def progress = Current.user&.progress || LearnerProgress.new(nil)

    def notification_bell = @notification_bell ||= NotificationBell.new(Current.user)

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
