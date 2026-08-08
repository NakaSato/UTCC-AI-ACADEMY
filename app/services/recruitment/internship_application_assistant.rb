module Recruitment
  class InternshipApplicationAssistant
    Item = Data.define(:key, :source)
    Guidance = Data.define(:items, :uncertainty)

    UNCERTAINTY = "Advisory rules-based preparation guidance only. It does not match, rank, accept, evaluate, or contact anyone, and it does not measure academic progress."
    ITEMS = {
      "pending" => [
        Item.new("review_learning_outcomes", "program.learning_outcomes"),
        Item.new("review_required_skills", "program.required_skills"),
        Item.new("prepare_questions", "program"),
        Item.new("wait_for_decision", "application.status")
      ],
      "accepted" => [
        Item.new("confirm_learning_goals", "program.learning_outcomes"),
        Item.new("plan_mentor_checkin", "program.mentor"),
        Item.new("review_required_skills", "program.required_skills")
      ],
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
      return unless @viewer&.student? && @application&.student_id.present? && @application.student_id == @viewer.id
      return unless Recruitment::InternshipProgram.published_for_candidates.where(id: @application.program_id).exists?

      Guidance.new(ITEMS.fetch(@application.status), UNCERTAINTY)
    end
  end
end
