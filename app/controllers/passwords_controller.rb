class PasswordsController < ApplicationController
  layout "auth", only: %i[ new edit ]

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to forgot_password_path, alert: t("flash.reset_throttled") }

  def new
  end

  # Most accounts have no email — sign-up asks only for a student ID — so this
  # reaches the few that do. The presence check matters: without it a blank
  # submission looks up email_address IS NULL and finds one of them.
  def create
    if params[:email_address].present? && (user = User.find_by(email_address: params[:email_address]))
      PasswordsMailer.reset(user).deliver_later
    end

    # Back to the same screen with the confirmation panel, and with no hint as
    # to whether that address had an account.
    redirect_to forgot_password_path(sent: 1)
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to login_path, notice: "ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว"
    else
      redirect_to reset_password_path(params[:token]), alert: "รหัสผ่านไม่ตรงกัน หรือสั้นกว่า 8 ตัวอักษร"
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to forgot_password_path, alert: "ลิงก์ตั้งรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว"
    end
end
