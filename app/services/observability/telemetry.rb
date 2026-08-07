require "json"

module Observability
  module Telemetry
    LOG_LEVELS = {
      "critical" => :error,
      "high" => :warn,
      "info" => :info
    }.freeze

    module_function

    def emit(event, **fields)
      signal = SignalCatalog.fetch(event)
      payload = signal.merge(
        timestamp: Time.current.iso8601,
        environment: Rails.env.to_s,
        release: ENV.fetch("RELEASE_SHA", ENV.fetch("GIT_SHA", "unknown")),
        request_id: Current.request_id,
        job_id: Current.job_id,
        fields: Redactor.call(fields)
      ).compact

      ActiveSupport::Notifications.instrument("observability.#{signal[:event]}", payload)
      Rails.logger.public_send(LOG_LEVELS.fetch(signal[:severity]), "[observability] #{JSON.generate(payload)}")
      payload
    end
  end
end
