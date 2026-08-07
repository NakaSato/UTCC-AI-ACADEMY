class CreateRecruitmentFoundation < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    add_index :organizations, :slug, unique: true

    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: false
      t.string :role, null: false, default: "recruiter"
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    add_index :organization_memberships, [ :organization_id, :user_id ], unique: true,
              name: "index_organization_memberships_on_organization_and_user"
    add_index :organization_memberships, :organization_id, unique: true,
              where: "role = 'owner' AND status = 'active'",
              name: "index_organization_memberships_on_active_owner"

    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :headline
      t.text :summary
      t.string :preferred_location
      t.string :visibility, null: false, default: "private"
      t.timestamps
    end

    add_index :candidate_profiles, :user_id, unique: true
  end
end
