class CreateRecruitmentJobPostSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_column :recruitment_job_posts, :hiring_reason, :text, null: false, default: ""
    add_column :recruitment_job_posts, :positions_count, :integer, null: false, default: 1
    add_check_constraint :recruitment_job_posts, "positions_count > 0", name: "recruitment_job_posts_positions_count"

    create_table :recruitment_job_post_suggestions do |t|
      t.references :job_post, null: false, foreign_key: { to_table: :recruitment_job_posts }, index: false
      t.references :requested_by, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.string :kind, null: false
      t.text :content, null: false, default: ""
      t.string :provider, null: false
      t.string :model
      t.string :source_label, null: false
      t.text :uncertainty, null: false
      t.jsonb :source_context, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.datetime :generated_at, null: false
      t.datetime :reviewed_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_job_post_suggestions, :job_post_id
    add_index :recruitment_job_post_suggestions, :requested_by_id
    add_index :recruitment_job_post_suggestions, :reviewed_by_id
    add_index :recruitment_job_post_suggestions, [ :job_post_id, :kind ],
              unique: true,
              name: "recruitment_job_suggestions_one_actionable",
              where: "status IN ('pending', 'edited')"
    add_check_constraint :recruitment_job_post_suggestions,
                         "kind IN ('summary', 'description', 'requirements', 'interview_questions', 'inclusive_language')",
                         name: "recruitment_job_suggestions_kind"
    add_check_constraint :recruitment_job_post_suggestions,
                         "status IN ('pending', 'edited', 'accepted', 'rejected')",
                         name: "recruitment_job_suggestions_status"
  end
end
