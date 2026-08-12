class ApplicationController < ActionController::Base
  include Authentication
  # After Authentication, so `require_authentication` runs first and a signed-out
  # visitor still lands on /login rather than the catalog.
  include Authorization
  # Shared with ErrorsController, which cannot inherit from here — see the
  # concern. It is what installs the `switch_locale` around_action.
  include Localization
  before_action :set_observability_context
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # The header's gem and streak counters sit on every signed-in screen, so this
  # is a helper rather than something each controller has to assign. The bell is
  # there for the same reason, and is also what names the channel it listens on.
  helper_method :progress, :notification_bell

  private
    def set_observability_context
      Current.request_id = request.request_id
    end

    def progress = Current.user&.progress || LearnerProgress.new(nil)

    # Where a company member's front door leads: the work waiting on their
    # company, or the chooser when they belong to more than one. It lives here
    # because two doors lead there — `/` and the console sign-in — and a member
    # of one company handed a list of one is the drift this prevents. SPEC-0048.
    def company_home_path(user)
      organizations = user.organizations.merge(Organization.active)

      organizations.one? ? work_company_path(organizations.first) : companies_path
    end

    def notification_bell = @notification_bell ||= NotificationBell.new(Current.user)
end
