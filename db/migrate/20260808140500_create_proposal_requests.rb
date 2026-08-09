class CreateProposalRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :proposal_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :category, null: false
      t.text :problem, null: false
      t.text :idea, null: false
      t.text :impact, null: false
      t.string :status, null: false, default: "submitted"
      t.timestamps

      t.check_constraint "category IN ('feature', 'curriculum', 'community', 'platform')",
                        name: "proposal_requests_category"
      t.check_constraint "status IN ('submitted', 'in_review', 'planned', 'declined')",
                        name: "proposal_requests_status"
    end

    add_index :proposal_requests, [ :user_id, :created_at ]
    add_index :proposal_requests, [ :status, :created_at ]
  end
end
