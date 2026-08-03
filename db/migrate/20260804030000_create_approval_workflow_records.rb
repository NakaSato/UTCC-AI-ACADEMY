class CreateApprovalWorkflowRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :approval_requests do |t|
      t.string :kind, null: false
      t.references :course, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.string :status, null: false, default: "pending"
      t.text :note
      t.datetime :decided_at
      t.timestamps
    end

    add_index :approval_requests, %i[course_id from_state to_state status],
              name: "index_approval_requests_on_course_transition"
    add_index :approval_requests, :status

    create_table :approval_decisions do |t|
      t.references :approval_request, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :outcome, null: false
      t.text :note
      t.timestamps
    end

    add_index :approval_decisions, %i[approval_request_id created_at],
              name: "index_approval_decisions_on_request_and_time"
  end
end
