class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    Current.job_id = job.job_id
    block.call
  rescue StandardError => error
    Observability::Telemetry.emit(
      "job.failure",
      job_class: job.class.name,
      queue: job.queue_name.to_s,
      error_class: error.class.name
    )
    raise
  ensure
    Current.job_id = nil
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
