class AdminController < ApplicationController
  allow_only :admin

  def show
    @tab = AdminConsole.tab_for(params[:tab])

    case @tab
    in :users
      # Both filters are whitelist-or-default; the search is a plain substring
      # over the two columns the roster shows.
      @role = AdminConsole.role_filter(params[:role])
      @query = params[:q].to_s.strip

      @users = User.order(:role, :name)
      @users = @users.where(role: @role) unless @role == :all
      if @query.present?
        needle = "%#{User.sanitize_sql_like(@query)}%"
        @users = @users.where("name LIKE :q OR student_id LIKE :q", q: needle)
      end
    in :integrity then @cases = Proctoring.cases
    in :audit then @level = AdminConsole.level_filter(params[:level])
    in :courses then @query = params[:q].to_s.strip
    else nil
    end
  end

  # Closing a case is stamping the learner's unreviewed events — there is no
  # case row, so there is nothing else to write. New events open a new case.
  def close_case
    user = User.find(params[:user_id])
    ProctorEvent.unreviewed.where(user:).update_all(reviewed_at: Time.current, updated_at: Time.current)

    redirect_to admin_path(tab: :integrity), notice: t("flash.integrity_closed", name: user.name)
  end

  def update
    user = User.find(params[:id])

    # An admin cannot change their own role. Only an admin reaches this action, so
    # that single rule is what guarantees the last admin cannot demote the site
    # into having none.
    if user == Current.user
      redirect_to admin_path, alert: t("flash.role_self")
    elsif user.update(role: params[:role])
      redirect_to admin_path,
                  notice: t("flash.role_changed", name: user.name, role: t("admin.roles.#{user.role}"))
    else
      redirect_to admin_path, alert: t("flash.role_invalid")
    end
  end
end
