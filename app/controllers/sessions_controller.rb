class SessionsController < ApplicationController
  layout "auth", only: :new

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "พยายามเข้าสู่ระบบบ่อยเกินไป กรุณาลองใหม่ในภายหลัง" }

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
end
