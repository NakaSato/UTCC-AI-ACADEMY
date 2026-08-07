class CreateRecruitmentJobDiscovery < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_saved_jobs do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :job_post, null: false, foreign_key: { to_table: :recruitment_job_posts }, index: false
      t.timestamps
    end
    add_index :recruitment_saved_jobs, [ :user_id, :job_post_id ], unique: true,
              name: "recruitment_saved_jobs_one_per_user"
    add_index :recruitment_saved_jobs, [ :user_id, :created_at ], name: "recruitment_saved_jobs_recent"

    create_table :recruitment_job_discovery_dismissals do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :job_post, null: false, foreign_key: { to_table: :recruitment_job_posts }, index: false
      t.timestamps
    end
    add_index :recruitment_job_discovery_dismissals, [ :user_id, :job_post_id ], unique: true,
              name: "recruitment_discovery_dismissals_one_per_user"

    create_table :recruitment_job_discovery_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.boolean :alerts_enabled, null: false, default: false
      t.boolean :alert_consent, null: false, default: false
      t.datetime :alert_consent_given_at
      t.string :alert_frequency, null: false, default: "weekly"
      t.string :search_query, null: false, default: ""
      t.string :location, null: false, default: ""
      t.string :employment_type, null: false, default: ""
      t.string :remote_policy, null: false, default: ""
      t.datetime :last_alert_sent_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :recruitment_job_discovery_preferences, :user_id, unique: true,
              name: "recruitment_discovery_preferences_one_per_user"
    add_check_constraint :recruitment_job_discovery_preferences,
                         "alert_frequency IN ('daily', 'weekly')",
                         name: "recruitment_discovery_preferences_frequency"
    add_check_constraint :recruitment_job_discovery_preferences,
                         "NOT alerts_enabled OR alert_consent",
                         name: "recruitment_discovery_preferences_consent"
  end
end
