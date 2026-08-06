Rails.application.config.after_initialize do
  Observability::Instrumentation.install
end
