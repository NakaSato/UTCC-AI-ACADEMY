module Recruitment
  class JobApplicationAssistant
    Recommendation = Data.define(:action, :attention, :stage_started_at, :threshold_days, :uncertainty)

    THRESHOLD_DAYS = {
      "submitted" => 7,
      "screening" => 5,
      "interview" => 3,
      "offer" => 2
    }.freeze
    ACTIONS = {
      "submitted" => "review_application",
      "screening" => "continue_screening",
      "interview" => "prepare_interview",
      "offer" => "review_offer",
      "accepted" => "close_record",
      "rejected" => "close_record",
      "withdrawn" => "close_record"
    }.freeze
    UNCERTAINTY = "Advisory workflow cue only. It does not rank, score, reject, contact, or advance a candidate, and stage timing may not reflect the recruiter's full context."

    def self.call(application:, viewer:, reference_time: Time.current)
      new(application:, viewer:, reference_time:).call
    end

    def initialize(application:, viewer:, reference_time:)
      @application = application
      @viewer = viewer
      @reference_time = reference_time
    end

    def call
      return unless @application&.reviewer?(@viewer)

      stage_started_at = @application.events.order(occurred_at: :desc, id: :desc).pick(:occurred_at) || @application.applied_at
      threshold_days = THRESHOLD_DAYS[@application.status]
      attention = threshold_days.present? && @reference_time >= stage_started_at + threshold_days.days
      Recommendation.new(ACTIONS.fetch(@application.status), attention, stage_started_at, threshold_days, UNCERTAINTY)
    end
  end
end
