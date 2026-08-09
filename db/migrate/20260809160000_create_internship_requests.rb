class CreateInternshipRequests < ActiveRecord::Migration[8.1]
  def change
    # A company is targetable only after an accountable member opts in, so an
    # unsolicited request cannot arrive through a channel nobody agreed to.
    add_column :organizations, :accepts_internship_requests, :boolean, null: false, default: false

    create_table :internship_requests do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :student, null: false, foreign_key: { to_table: :users }, index: false
      t.references :decided_by, foreign_key: { to_table: :users }, index: false
      # No program reference by design: a request is strictly position-less, which
      # is what keeps it from becoming a second Recruitment::InternshipApplication.
      t.text :motivation, null: false
      t.text :learning_goals, null: false
      t.string :status, null: false, default: "draft"
      t.text :decision_reason
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.datetime :decided_at
      t.datetime :withdrawn_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :internship_requests, [ :organization_id, :status ]
    add_index :internship_requests, [ :student_id, :status ]
    add_index :internship_requests, :decided_by_id
    # One open request per student per organization; a decided or withdrawn
    # request leaves the partial index, which is what allows a re-approach.
    add_index :internship_requests, [ :organization_id, :student_id ],
              unique: true,
              name: "internship_requests_one_open",
              where: "decided_at IS NULL AND withdrawn_at IS NULL"
    add_check_constraint :internship_requests,
                         "status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn')",
                         name: "internship_requests_status"
    # A rejection has to say why; an approval does not need a reason.
    add_check_constraint :internship_requests,
                         "status <> 'rejected' OR (decision_reason IS NOT NULL AND decision_reason <> '')",
                         name: "internship_requests_rejection_reason"
  end
end
