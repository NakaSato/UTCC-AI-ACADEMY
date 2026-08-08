module Recruitment
  class CandidateApplicationAssistant
    Item = Data.define(:key, :source)
    Guidance = Data.define(:items, :uncertainty)

    UNCERTAINTY = "Advisory rules-based preparation guidance only. It does not assess your qualifications, predict hiring, contact an employer, submit an application, or replace human career advice."
    ITEMS = {
      "submitted" => [
        Item.new("review_submitted_materials", "application.statement"),
        Item.new("wait_for_review", "application.status")
      ],
      "screening" => [
        Item.new("prepare_evidence_examples", "application.status + job_post"),
        Item.new("review_role_requirements", "job_post")
      ],
      "interview" => [
        Item.new("review_role_requirements", "job_post"),
        Item.new("prepare_interview_questions", "application.status")
      ],
      "offer" => [
        Item.new("review_offer_details", "application.status"),
        Item.new("ask_for_human_guidance", "application.status")
      ],
      "accepted" => [ Item.new("record_next_steps", "application.status") ],
      "rejected" => [ Item.new("record_outcome", "application.status") ],
      "withdrawn" => [ Item.new("record_outcome", "application.status") ]
    }.freeze

    def self.call(application:, viewer:)
      new(application:, viewer:).call
    end

    def initialize(application:, viewer:)
      @application = application
      @viewer = viewer
    end

    def call
      return unless @viewer&.student? && @application&.candidate_id.present? && @application.candidate_id == @viewer.id

      Guidance.new(ITEMS.fetch(@application.status), UNCERTAINTY)
    end
  end
end
