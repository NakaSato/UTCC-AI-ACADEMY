class CreateAcademicPostCollaboration < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_post_memberships do |t|
      t.references :academic_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :permission, null: false, default: "viewer"
      t.datetime :revoked_at
      t.timestamps

      t.index [ :academic_post_id, :user_id ], unique: true
      t.check_constraint "permission IN ('viewer', 'editor')",
                        name: "academic_post_memberships_permission"
    end

    create_table :academic_post_invitations do |t|
      t.references :academic_post, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.string :permission, null: false, default: "viewer"
      t.string :token_digest, null: false, limit: 64
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.timestamps

      t.index :token_digest, unique: true
      t.index [ :invitee_id, :accepted_at, :revoked_at ]
      t.index [ :academic_post_id, :invitee_id ],
              unique: true,
              where: "accepted_at IS NULL AND revoked_at IS NULL",
              name: "academic_post_invitations_one_pending"
      t.check_constraint "permission IN ('viewer', 'editor')",
                        name: "academic_post_invitations_permission"
      t.check_constraint "inviter_id <> invitee_id",
                        name: "academic_post_invitations_not_self"
    end
  end
end
