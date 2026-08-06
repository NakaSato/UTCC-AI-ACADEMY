module Observability
  module SignalCatalog
    REQUIRED_KEYS = %i[
      event metric symptom threshold severity owner response_window runbook escalation suppression
    ].freeze

    SIGNALS = [
      {
        event: "http.request.failure",
        metric: "http.server.errors",
        symptom: "Learner or staff HTTP requests return 5xx responses",
        threshold: "Page Platform Owner when 5xx responses exceed 5% for 5 minutes",
        severity: "high",
        owner: "Platform Owner",
        response_window: "Acknowledge within 15 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#http-request-failure",
        escalation: "Tech Lead after 15 minutes or when authentication is affected",
        suppression: "Group by route and release; suppress duplicate events for 5 minutes"
      },
      {
        event: "database.query.failure",
        metric: "database.errors",
        symptom: "Application queries or connections fail",
        threshold: "Page Platform Owner on any sustained failure for 1 minute",
        severity: "critical",
        owner: "Platform Owner",
        response_window: "Acknowledge within 10 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#database-query-failure",
        escalation: "Tech Lead immediately when writes or authentication are affected",
        suppression: "Group by database operation and error class; suppress duplicates for 5 minutes"
      },
      {
        event: "job.failure",
        metric: "jobs.failed",
        symptom: "A background job fails after a user-facing request returns",
        threshold: "Page Platform Owner on any terminal failure of a critical queue job",
        severity: "high",
        owner: "Platform Owner",
        response_window: "Acknowledge within 15 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#job-failure",
        escalation: "Tech Lead when queue latency exceeds 5 minutes or retries are exhausted",
        suppression: "Group by job class and queue; suppress duplicate job IDs"
      },
      {
        event: "mail.delivery.failure",
        metric: "mail.delivery.errors",
        symptom: "Password-reset mail cannot be handed to the configured SMTP transport",
        threshold: "Page Platform Owner on any delivery failure; do not expose it to the requester",
        severity: "high",
        owner: "Platform Owner",
        response_window: "Acknowledge within 15 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#mail-delivery-failure",
        escalation: "Tech Lead when failures persist for 5 minutes; production provider owner when configured",
        suppression: "Group by mailer/action and error class; suppress duplicates for 5 minutes"
      },
      {
        event: "websocket.connection.failure",
        metric: "websocket.connection.errors",
        symptom: "Action Cable cannot establish a connection because the server path fails",
        threshold: "Page Platform Owner when non-authentication failures exceed 5% for 5 minutes",
        severity: "high",
        owner: "Platform Owner",
        response_window: "Acknowledge within 15 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#websocket-connection-failure",
        escalation: "Tech Lead when authenticated notifications are unavailable",
        suppression: "Exclude expected authentication denials; group by error class and release"
      },
      {
        event: "security.audit.failure",
        metric: "security.audit.errors",
        symptom: "A durable security or academic-integrity event cannot be recorded",
        threshold: "Page Security Owner and Platform Owner on any persistence failure",
        severity: "critical",
        owner: "Security Owner",
        response_window: "Acknowledge within 10 minutes",
        runbook: "docs/runbooks/rb-critical-failure-observability.md#security-audit-failure",
        escalation: "Tech Lead immediately; preserve the learner-facing failure and investigate the transaction",
        suppression: "Group by event action and error class; do not suppress distinct actions"
      }
    ].freeze

    module_function

    def all = SIGNALS

    def fetch(event)
      SIGNALS.find { |signal| signal[:event] == event.to_s } || raise(KeyError, "Unknown observability signal: #{event}")
    end
  end
end
