class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: "ลองใหม่อีกครั้งในภายหลัง" }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "ยินดีต้อนรับสู่ UTCC AI Fundamental"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.expect(user: [ :name, :email_address, :password, :password_confirmation,
                            :faculty, :study_year ])
    end
end
