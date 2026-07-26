class ApplicationController < ActionController::Base
  include Authentication
  # After Authentication, so `require_authentication` runs first and a signed-out
  # visitor still lands on /login rather than the catalog.
  include Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  # The header's gem and streak counters sit on every signed-in screen, so this
  # is a helper rather than something each controller has to assign.
  helper_method :progress

  private
    def progress = Current.user&.progress || LearnerProgress.new(nil)

    # The language toggle in the header writes session[:locale]; every request
    # reads it back here. Falls back to Thai, the default locale.
    def switch_locale(&)
      I18n.with_locale(session[:locale] || I18n.default_locale, &)
    end
end
