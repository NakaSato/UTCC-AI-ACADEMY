class SessionsController < ApplicationController
  layout "auth", only: :new

  allow_unauthenticated_access only: %i[ new create ]

  # Two limits, because they stop different things. The first is the default
  # `by: request.remote_ip`, which slows one machine working through a list. The
  # second keys on the account being tried, so guessing spread across many
  # addresses is throttled too — an IP-only limit is no obstacle at all to
  # someone with a list of real student IDs and more than one source.
  #
  # `name:` is what lets the two coexist; without it the second would replace the
  # first. Blank submissions all share one bucket, which is fine.
  rate_limit to: 10, within: 3.minutes, name: "ip", only: :create,
             with: -> { redirect_to login_path, alert: t("flash.login_throttled") }
  rate_limit to: 10, within: 3.minutes, name: "account", only: :create,
             by: -> { params[:student_id].to_s },
             with: -> { redirect_to login_path, alert: t("flash.login_throttled") }

  # The sign-up form shares this screen as the second tab, so this action has
  # to prepare it too — see shared/_auth_switch.
  def new
    @user = User.new
    @accepted_terms = false
  end

  # Students sign in with their student ID; most accounts have no email at all.
  def create
    if user = User.authenticate_by(params.permit(:student_id, :password))
      start_new_session_for user, remember: params[:remember_me] == "1"
      redirect_to after_authentication_url
    else
      redirect_to login_path, alert: "รหัสนักศึกษาหรือรหัสผ่านไม่ถูกต้อง"
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, status: :see_other
  end

  def destroy_other_sessions
    Current.user.sessions.live.where.not(id: Current.session.id).destroy_all
    redirect_to profile_path, notice: t("flash.other_sessions_revoked")
  end

  def destroy_session
    target = Session.find_signed(params[:token], purpose: Session::REVOCATION_PURPOSE)
    session = Current.user.sessions.live.find_by(id: target&.id)

    if session && session.id != Current.session.id
      session.destroy!
      redirect_to profile_path, notice: t("flash.session_revoked")
    else
      redirect_to profile_path, alert: t("flash.session_revoke_invalid")
    end
  end
end
