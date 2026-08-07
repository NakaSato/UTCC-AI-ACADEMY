class CreateRecruitmentJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_job_applications do |t|
      t.references :job_post, null: false, foreign_key: { to_table: :recruitment_job_posts }, index: false
      t.references :candidate, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.string :status, null: false, default: "submitted"
      t.text :statement, null: false, default: ""
      t.jsonb :application_snapshot, null: false, default: {}
      t.datetime :applied_at, null: false
      t.datetime :reviewed_at
      t.datetime :withdrawn_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :recruitment_job_applications, [ :job_post_id, :candidate_id ], unique: true,
              name: "recruitment_job_applications_one_per_candidate"
    add_index :recruitment_job_applications, [ :job_post_id, :status, :created_at ],
              name: "recruitment_job_applications_pipeline"
    add_check_constraint :recruitment_job_applications,
                         "status IN ('submitted', 'screening', 'interview', 'offer', 'accepted', 'rejected', 'withdrawn')",
                         name: "recruitment_job_applications_status"

    create_table :recruitment_job_application_events do |t|
      t.references :job_application, null: false,
                   foreign_key: { to_table: :recruitment_job_applications }, index: false
      t.references :actor, null: false, foreign_key: { to_table: :users }, index: false
      t.string :from_status
      t.string :to_status, null: false
      t.text :note, null: false, default: ""
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :recruitment_job_application_events, [ :job_application_id, :occurred_at, :id ],
              name: "recruitment_job_application_events_history"
    add_check_constraint :recruitment_job_application_events,
                         "to_status IN ('submitted', 'screening', 'interview', 'offer', 'accepted', 'rejected', 'withdrawn')",
                         name: "recruitment_job_application_events_to_status"
    add_check_constraint :recruitment_job_application_events,
                         "from_status IS NULL OR from_status IN ('submitted', 'screening', 'interview', 'offer', 'accepted', 'rejected', 'withdrawn')",
                         name: "recruitment_job_application_events_from_status"
  end
end
