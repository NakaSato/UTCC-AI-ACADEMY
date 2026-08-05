class ProfilesController < ApplicationController
  # The one screen where a student edits their own record, and the only way an
  # account ever acquires an email address: sign-up asks for a name, a student
  # ID and a password and nothing else. That matters beyond tidiness —
  # PasswordsController#create finds a user by email and by nothing else, so an
  # account with no address has no way back in when the password is forgotten.
  #
  # Faculty and study year are here for the same reason. They are shown on My
  # Learning through User#display_affiliation, sign-up stopped asking for them,
  # and until now nothing in the app could set them.
  #
  # The password form is the other half of that. /reset-password is the
  # signed-out way in and needs mail to work; this is the signed-in one and
  # needs nothing, which until now left a student who simply wanted a new
  # password with no route to one at all.
  #
  # Two forms on one screen, two actions, one record — so each render says which
  # form the errors belong to. Without `@errors_on` a rejected password would
  # report itself above the name and email fields.
  rate_limit to: 10, within: 3.minutes, only: :update_password,
             with: -> { redirect_to profile_path, alert: t("flash.password_throttled") }

  def edit
    @user = Current.user
    load_sessions
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to profile_path, notice: t("flash.profile_saved")
    else
      @errors_on = :profile
      load_sessions
      render :edit, status: :unprocessable_entity
    end
  end

  # The session cookie is the only thing standing between a borrowed laptop and
  # a changed password, so the current one is asked for again here. `authenticate`
  # is bcrypt's own comparison — a wrong answer is a validation failure on a
  # field that is not a column, which is why it is added by hand.
  def update_password
    @user = Current.user

    unless @user.authenticate(params[:current_password].to_s)
      @user.errors.add(:current_password, :invalid)
      @errors_on = :password
      load_sessions
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(password_params)
      # Everywhere else this account is signed in is now signed in with a
      # password its holder has replaced. This session is spared — being made to
      # sign in again on the machine you just used reads as a failure.
      @user.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to profile_path, notice: t("flash.password_changed")
    else
      @errors_on = :password
      load_sessions
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def load_sessions
      @sessions = @user.sessions.live.order(created_at: :desc, id: :desc)
    end

    # What a student may change about themselves, spelled out rather than
    # inferred from the form. Two absences are deliberate and must stay:
    #
    #   :student_id — it is what sign-in authenticates on and what the roster,
    #                 the sections and every completion are read against. It is
    #                 issued by the university, not chosen here.
    #   :role       — /admin is the only place a role is granted, exactly as in
    #                 RegistrationsController#user_params. Permitting it here
    #                 would let any student post their way to admin.
    def profile_params
      params.expect(user: [ :name, :email_address, :faculty, :study_year ])
    end

    # Not nested under `user:`, so there is no chance of a stray attribute
    # riding along with a password change. User's own rules do the rest — 8–72
    # characters, a letter and a digit, not a common one, not the student ID.
    def password_params
      { password: params[:password], password_confirmation: params[:password_confirmation] }
    end
end
