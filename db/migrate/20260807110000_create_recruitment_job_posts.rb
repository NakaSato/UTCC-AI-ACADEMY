class CreateRecruitmentJobPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_job_posts do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :creator, null: false, foreign_key: { to_table: :users }, index: false
      t.string :title, null: false, default: ""
      t.text :summary, null: false, default: ""
      t.text :description, null: false, default: ""
      t.string :category, null: false, default: ""
      t.string :department, null: false, default: ""
      t.string :team, null: false, default: ""
      t.string :seniority, null: false, default: ""
      t.string :employment_type, null: false, default: "full_time"
      t.string :location, null: false, default: ""
      t.string :remote_policy, null: false, default: "onsite"
      t.integer :salary_min
      t.integer :salary_max
      t.string :currency, null: false, default: "THB", limit: 3
      t.date :closes_on
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :closed_at
      t.datetime :archived_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_job_posts, :organization_id
    add_index :recruitment_job_posts, :creator_id
    add_index :recruitment_job_posts, [ :organization_id, :status, :updated_at ],
              name: "recruitment_job_posts_management"
    add_index :recruitment_job_posts, [ :status, :closes_on, :published_at ],
              name: "recruitment_job_posts_candidate_visibility"
    add_check_constraint :recruitment_job_posts,
                         "status IN ('draft', 'review', 'published', 'paused', 'closed', 'archived')",
                         name: "recruitment_job_posts_status"
    add_check_constraint :recruitment_job_posts,
                         "employment_type IN ('full_time', 'part_time', 'internship', 'contract', 'freelance')",
                         name: "recruitment_job_posts_employment_type"
    add_check_constraint :recruitment_job_posts,
                         "remote_policy IN ('onsite', 'hybrid', 'remote')",
                         name: "recruitment_job_posts_remote_policy"
    add_check_constraint :recruitment_job_posts,
                         "salary_min IS NULL OR salary_min >= 0",
                         name: "recruitment_job_posts_salary_min"
    add_check_constraint :recruitment_job_posts,
                         "salary_max IS NULL OR salary_max >= 0",
                         name: "recruitment_job_posts_salary_max"
    add_check_constraint :recruitment_job_posts,
                         "salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max",
                         name: "recruitment_job_posts_salary_range"
  end
end
