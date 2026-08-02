class CreateAcademicPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_posts do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "draft"
      t.string :title, null: false, default: ""
      t.text :body, null: false, default: ""
      t.integer :lock_version, null: false, default: 0
      t.timestamps

      t.index [ :owner_id, :status ]
    end

    create_table :academic_post_revisions do |t|
      t.references :academic_post, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :version, null: false
      t.string :title, null: false, default: ""
      t.text :body, null: false, default: ""
      t.timestamps

      t.index [ :academic_post_id, :version ], unique: true
    end
  end
end
