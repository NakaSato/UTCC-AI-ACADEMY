class CreateOrganizationInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_invitations do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :inviter, null: false, foreign_key: { to_table: :users }, index: false
      t.references :invitee, null: false, foreign_key: { to_table: :users }, index: false
      t.string :role, null: false, default: "recruiter"
      t.string :token_digest, null: false, limit: 64
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :organization_invitations, :token_digest, unique: true
    add_index :organization_invitations, :organization_id
    add_index :organization_invitations, :inviter_id
    add_index :organization_invitations, :invitee_id
    add_index :organization_invitations, [ :organization_id, :invitee_id ],
              unique: true,
              name: "organization_invitations_one_open",
              where: "accepted_at IS NULL AND declined_at IS NULL AND revoked_at IS NULL"
    add_check_constraint :organization_invitations,
                         "role IN ('recruiter', 'hiring_manager', 'mentor')",
                         name: "organization_invitations_role"
    add_check_constraint :organization_invitations,
                         "NOT (accepted_at IS NOT NULL AND declined_at IS NOT NULL)",
                         name: "organization_invitations_one_decision"
  end
end
