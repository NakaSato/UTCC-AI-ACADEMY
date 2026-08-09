class CreateBusinessCaseCollaboration < ActiveRecord::Migration[8.1]
  def change
    create_table :business_cases do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :owner, null: false, foreign_key: { to_table: :users }, index: false
      t.string :title, null: false, limit: 160
      t.text :brief
      t.text :requirements
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :closed_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :business_cases, [ :organization_id, :status ]
    add_index :business_cases, :owner_id
    add_check_constraint :business_cases,
                         "status IN ('draft', 'published', 'closed')",
                         name: "business_cases_status"

    create_table :business_case_invitations do |t|
      t.references :business_case, null: false, foreign_key: true, index: false
      t.references :inviter, null: false, foreign_key: { to_table: :users }, index: false
      t.references :invitee, null: false, foreign_key: { to_table: :users }, index: false
      t.string :token_digest, null: false, limit: 64
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :business_case_invitations, :token_digest, unique: true
    add_index :business_case_invitations, :business_case_id
    add_index :business_case_invitations, :inviter_id
    add_index :business_case_invitations, :invitee_id
    add_index :business_case_invitations, [ :business_case_id, :invitee_id ],
              unique: true,
              name: "business_case_invitations_one_open",
              where: "accepted_at IS NULL AND declined_at IS NULL AND revoked_at IS NULL"
    add_check_constraint :business_case_invitations,
                         "NOT (accepted_at IS NOT NULL AND declined_at IS NOT NULL)",
                         name: "business_case_invitations_one_decision"

    create_table :business_case_participants do |t|
      t.references :business_case, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.references :assigned_by, foreign_key: { to_table: :users }, index: false
      t.string :role, null: false
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :business_case_participants, :business_case_id
    add_index :business_case_participants, :user_id
    add_index :business_case_participants, [ :business_case_id, :user_id ],
              unique: true,
              name: "business_case_participants_one_active",
              where: "revoked_at IS NULL"
    add_check_constraint :business_case_participants,
                         "role IN ('student', 'mentor')",
                         name: "business_case_participants_role"

    create_table :business_case_milestones do |t|
      t.references :business_case, null: false, foreign_key: true, index: false
      t.string :title, null: false, limit: 160
      t.text :description
      t.integer :position, null: false
      t.string :status, null: false, default: "open"
      t.datetime :completed_at
      t.timestamps
    end

    add_index :business_case_milestones, [ :business_case_id, :position ], unique: true
    add_check_constraint :business_case_milestones,
                         "status IN ('open', 'completed')",
                         name: "business_case_milestones_status"

    create_table :business_case_submissions do |t|
      t.references :business_case, null: false, foreign_key: true, index: false
      t.references :business_case_milestone, null: false, foreign_key: true, index: false
      t.references :author, null: false, foreign_key: { to_table: :users }, index: false
      t.text :body, null: false
      t.integer :version, null: false, default: 1
      t.datetime :submitted_at, null: false
      t.timestamps
    end

    add_index :business_case_submissions, :business_case_id
    add_index :business_case_submissions, :author_id
    add_index :business_case_submissions, [ :business_case_milestone_id, :author_id, :version ],
              unique: true,
              name: "business_case_submissions_one_version"
    add_check_constraint :business_case_submissions,
                         "version >= 1",
                         name: "business_case_submissions_version"

    create_table :business_case_comments do |t|
      t.references :business_case, null: false, foreign_key: true, index: false
      t.references :author, null: false, foreign_key: { to_table: :users }, index: false
      t.text :body, null: false
      t.datetime :posted_at, null: false
      t.timestamps
    end

    add_index :business_case_comments, [ :business_case_id, :id ]
    add_index :business_case_comments, :author_id
  end
end
