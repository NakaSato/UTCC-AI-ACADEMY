module Observability
  class Instrumentation
    class << self
      def install
        return if @installed

        @installed = true
        subscribe_to_controller_failures
        subscribe_to_database_failures
        subscribe_to_mail_failures
      end

      private
        # Telemetry is named in full in all three subscribers, and has to be. A
        # subscriber block outlives the class that defined it: in development
        # the next reload replaces this class, the block keeps the old one as
        # its lexical scope, and a bare `Telemetry` then resolves against a
        # namespace that no longer exists. Qualifying it starts the lookup at
        # Object, which is always the current Observability.
        def subscribe_to_controller_failures
          ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
            payload = args.last
            next unless payload[:exception].present? || payload[:status].to_i >= 500

            Observability::Telemetry.emit(
              "http.request.failure",
              controller: payload[:controller],
              action: payload[:action],
              status: payload[:status].to_i,
              error_class: payload[:exception]&.first
            )
          end
        end

        def subscribe_to_database_failures
          ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
            payload = args.last
            next unless payload[:exception]

            Observability::Telemetry.emit(
              "database.query.failure",
              operation: payload[:name],
              error_class: payload[:exception].first
            )
          end
        end

        def subscribe_to_mail_failures
          ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |*args|
            payload = args.last
            next unless payload[:exception]

            Observability::Telemetry.emit(
              "mail.delivery.failure",
              mailer: payload[:mailer],
              action: payload[:action],
              error_class: payload[:exception].first
            )
          end
        end
    end
  end
end
