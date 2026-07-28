module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # `live`, never a bare `find_by` — a session past Session::MAX_AGE is not a
    # session, and a cookie that outlives its row must resolve to nobody.
    # ApplicationCable::Connection does the same lookup and has to match.
    def find_session_by_cookie
      Session.live.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    # Denial sends a visitor to the front door, not to the form — `/` is the
    # landing page when there is no session, so it explains the app rather than
    # demanding credentials for a screen they may not have meant to open. Same
    # shape as `Authorization#authorize_role`: root plus a flash saying why.
    #
    # The stash still happens, so a deep link survives the detour — sign in from
    # the landing page and `after_authentication_url` returns the original screen.
    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to root_path, alert: t("flash.sign_in_required")
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    # `remember` backs the "remember me on this device" checkbox on the sign-in
    # screen: without it the cookie lasts only as long as the browser session.
    #
    # Either way the cookie now expires with the row rather than outliving it —
    # `permanent` was twenty years against a record that Session::MAX_AGE stops
    # honouring after thirty days, so the browser kept sending a dead id.
    def start_new_session_for(user, remember: true)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookie = { value: session.id, httponly: true, same_site: :lax }
        cookie[:expires] = Session::MAX_AGE.from_now if remember
        cookies.signed[:session_id] = cookie
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
