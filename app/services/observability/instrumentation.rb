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
        def subscribe_to_controller_failures
          ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
            payload = args.last
            next unless payload[:exception].present? || payload[:status].to_i >= 500

            Telemetry.emit(
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

            Telemetry.emit(
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

            Telemetry.emit(
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
