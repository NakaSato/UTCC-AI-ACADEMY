module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      # `usable`, matching Authentication#find_session_by_cookie — a rule
      # enforced in only one of the two places that resolve this cookie is a rule
      # that can be walked around. This is no longer hypothetical: every
      # signed-in page subscribes the notification bell, so a dead session's
      # cookie is offered here on every screen. The scope carries two rules now,
      # the session's age and whether the account behind it is suspended, and
      # both have to hold in both places.
      def set_current_user
        if session = Session.usable.find_by(id: cookies.signed[:session_id])
          self.current_user = session.user
        end
      rescue ActiveRecord::ActiveRecordError => error
        Observability::Telemetry.emit("websocket.connection.failure", error_class: error.class.name)
        reject_unauthorized_connection
      end
  end
end
