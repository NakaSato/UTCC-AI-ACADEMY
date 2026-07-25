class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "ขอลิงก์บ่อยเกินไป กรุณาลองใหม่ในภายหลัง" }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "ส่งลิงก์ตั้งรหัสผ่านใหม่แล้ว (หากมีบัญชีที่ใช้อีเมลนี้)"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว"
    else
      redirect_to edit_password_path(params[:token]), alert: "รหัสผ่านไม่ตรงกัน หรือสั้นกว่า 8 ตัวอักษร"
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "ลิงก์ตั้งรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว"
    end
end
