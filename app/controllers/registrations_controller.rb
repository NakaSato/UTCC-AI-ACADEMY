class RegistrationsController < ApplicationController
  # `only:` filters by **action**, not by template, and #create renders :new when
  # validation fails. Without `create` in this list that re-render came back on
  # layouts/application — marketing header, no hero, full-bleed fields — which is
  # the one screen a student is guaranteed to see when they get sign-up wrong.
  # The other two auth controllers redirect on failure, so only this one needs it.
  layout "auth", only: %i[ new create ]

  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to register_path, alert: "ลองใหม่อีกครั้งในภายหลัง" }

  def new
    @user = User.new
    @accepted_terms = false
  end

  def create
    @user = User.new(user_params)
    @accepted_terms = params[:terms] == "1"

    if @accepted_terms && @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "ยินดีต้อนรับสู่ UTCC AI Academy"
    else
      # The checkbox is `required` in the markup too; this is the backstop for
      # anything that posts the form without it.
      @user.errors.add(:base, t("auth.terms_required")) unless @accepted_terms
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      # :student_id, not :email_address — the ID is the credential, and nothing
      # derives an address from it. Faculty and study year are not asked for
      # here either. All three are set afterwards on /profile, which is the only
      # screen that writes them (see ProfilesController and the note there about
      # what an account with no address cannot do).
      #
      # :role is deliberately absent and must stay absent — sign-up may only ever
      # produce a student. Instructor and admin are granted from /admin, and
      # adding :role here would let anyone post their way to the roster.
      params.expect(user: [ :name, :student_id, :password, :password_confirmation ])
    end
end
