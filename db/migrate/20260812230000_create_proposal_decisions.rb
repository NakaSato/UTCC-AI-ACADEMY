class CreateProposalDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :proposal_decisions do |t|
      t.references :proposal_request, null: false, foreign_key: true, index: false
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :to_status, null: false
      t.text :reason, null: false
      t.timestamps

      t.index [ :proposal_request_id, :created_at ], name: "proposal_decisions_history"
      # `submitted` is deliberately absent: it is what the intake writes, and
      # nothing decides a proposal into it. SPEC-0050.
      t.check_constraint "to_status IN ('in_review', 'planned', 'declined')",
                         name: "proposal_decisions_to_status"
      t.check_constraint "length(reason) BETWEEN 1 AND 1000",
                         name: "proposal_decisions_reason"
    end
  end
end
