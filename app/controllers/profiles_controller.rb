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
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to profile_path, notice: t("flash.profile_saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
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
end
