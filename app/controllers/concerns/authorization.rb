module Authorization
  extend ActiveSupport::Concern

  class_methods do
    # Shaped like `allow_unauthenticated_access`: it names who is allowed in, not
    # what is forbidden. Any User predicate works, so `:staff` covers instructor
    # and admin at once.
    def allow_only(*roles, **options)
      before_action(**options) { authorize_role(roles) }
    end
  end

  private
    # `require_authentication` runs first and has already sent a signed-out
    # visitor to the landing page, so reaching here without a user is not
    # expected — the safe navigation is there so a misordered callback cannot
    # raise. Both denials land on root now; the ordering is what decides which
    # of the two flashes a visitor gets.
    def authorize_role(roles)
      return if roles.any? { Current.user&.public_send("#{it}?") }

      redirect_to root_path, alert: t("flash.forbidden")
    end
end
