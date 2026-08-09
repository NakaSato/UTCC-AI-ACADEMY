class ConsoleSessionsController < ApplicationController
  layout "auth"

  allow_unauthenticated_access

  # The same two keys SessionsController uses, and for the same reasons: the
  # default IP key slows one machine working through a list, and the second keys
  # on the account being tried so guessing spread across many addresses is
  # throttled too. `name:` is what lets the two coexist.
  rate_limit to: 10, within: 3.minutes, name: "ip", only: :create,
             with: -> { redirect_to console_path, alert: t("flash.login_throttled") }
  rate_limit to: 10, within: 3.minutes, name: "account", only: :create,
             by: -> { params[:identifier].to_s.strip.downcase },
             with: -> { redirect_to console_path, alert: t("flash.login_throttled") }

  # The console hero, not the student one — a recruiter is not here to start an
  # AI journey. See shared/_auth_hero, which takes the scope as a local.
  def new
    @auth_scope = "auth.console"
  end

  def create
    if user = authenticate_console_user
      start_new_session_for user, remember: params[:remember_me] == "1"
      redirect_to after_console_authentication_url(user)
    else
      redirect_to console_path, alert: t("flash.console_login_failed")
    end
  end

  private
    # An account without console access is refused here rather than signed in and
    # turned away later: no session is created, and the flash is the same one a
    # wrong password gets, so /console cannot be used to ask which accounts are
    # staff. A student whose password is correct still has /login.
    def authenticate_console_user
      user = User.authenticate_by(credentials)
      user if user&.console_access?
    end

    # One field, three credentials, told apart by shape alone: an "@" is an email
    # address, all digits is a student ID, and anything else is a username —
    # which is why User::USERNAME_FORMAT insists on a letter. Every one of the
    # three columns is unique and normalised on the model, so `authenticate_by`
    # matches what was stored whatever case or spacing was typed.
    #
    # A console account created by an admin has no student ID at all; the digit
    # branch is here for the staff accounts that predate that and for anyone who
    # is genuinely both.
    def credentials
      identifier = params[:identifier].to_s.strip
      password = params[:password].to_s

      case identifier
      when /@/ then { email_address: identifier, password: password }
      when /\A\d+\z/ then { student_id: identifier, password: password }
      else { username: identifier, password: password }
      end
    end

    # A deep link still wins: a company member who was sent to the front door by
    # `require_authentication` comes back to the screen they asked for. With
    # nothing stashed, each role lands on its own console.
    def after_console_authentication_url(user)
      session.delete(:return_to_after_authenticating) || console_home_url(user)
    end

    # Admin first, because an admin is also staff and /admin is the wider screen.
    def console_home_url(user)
      if user.admin?
        admin_url
      elsif user.instructor?
        instructor_url
      else
        recruitment_organizations_url
      end
    end
end
