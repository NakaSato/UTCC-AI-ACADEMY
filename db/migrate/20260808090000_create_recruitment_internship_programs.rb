class CreateRecruitmentInternshipPrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_internship_programs do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :creator, null: false, foreign_key: { to_table: :users }, index: false
      t.references :mentor, foreign_key: { to_table: :users }, index: false
      t.string :name, null: false, default: ""
      t.string :department, null: false, default: ""
      t.text :description, null: false, default: ""
      t.integer :duration_weeks, null: false, default: 1
      t.integer :max_students, null: false, default: 1
      t.text :required_skills, null: false, default: ""
      t.text :learning_outcomes, null: false, default: ""
      t.text :working_days, null: false, default: ""
      t.string :remote_policy, null: false, default: "onsite"
      t.boolean :paid, null: false, default: false
      t.string :certificate_policy, null: false, default: ""
      t.text :equipment_provided, null: false, default: ""
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :closed_at
      t.datetime :archived_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_internship_programs, :organization_id
    add_index :recruitment_internship_programs, [ :organization_id, :status, :updated_at ],
              name: "recruitment_internship_programs_management"
    add_index :recruitment_internship_programs, [ :status, :published_at ],
              name: "recruitment_internship_programs_publication"
    add_check_constraint :recruitment_internship_programs,
                         "status IN ('draft', 'review', 'published', 'paused', 'closed', 'archived')",
                         name: "recruitment_internship_programs_status"
    add_check_constraint :recruitment_internship_programs,
                         "duration_weeks BETWEEN 1 AND 104",
                         name: "recruitment_internship_programs_duration"
    add_check_constraint :recruitment_internship_programs,
                         "max_students > 0",
                         name: "recruitment_internship_programs_capacity"
    add_check_constraint :recruitment_internship_programs,
                         "remote_policy IN ('onsite', 'hybrid', 'remote')",
                         name: "recruitment_internship_programs_remote_policy"

    create_table :recruitment_internship_applications do |t|
      t.references :program, null: false, foreign_key: { to_table: :recruitment_internship_programs }, index: false
      t.references :student, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.text :statement, null: false, default: ""
      t.string :status, null: false, default: "pending"
      t.datetime :applied_at, null: false
      t.datetime :reviewed_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_internship_applications, [ :program_id, :student_id ], unique: true,
              name: "recruitment_internship_applications_one_per_student"
    add_index :recruitment_internship_applications, [ :program_id, :status, :created_at ],
              name: "recruitment_internship_applications_program_status"
    add_check_constraint :recruitment_internship_applications,
                         "status IN ('pending', 'accepted', 'rejected', 'withdrawn')",
                         name: "recruitment_internship_applications_status"

    create_table :recruitment_internship_evaluations do |t|
      t.references :application, null: false, foreign_key: { to_table: :recruitment_internship_applications }, index: false
      t.references :evaluator, null: false, foreign_key: { to_table: :users }, index: false
      t.integer :rating
      t.boolean :learning_outcomes_met
      t.text :feedback, null: false, default: ""
      t.text :next_steps, null: false, default: ""
      t.string :status, null: false, default: "draft"
      t.datetime :submitted_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_internship_evaluations, :application_id, unique: true,
              name: "recruitment_internship_evaluations_one_per_application"
    add_check_constraint :recruitment_internship_evaluations,
                         "status IN ('draft', 'submitted')",
                         name: "recruitment_internship_evaluations_status"
    add_check_constraint :recruitment_internship_evaluations,
                         "rating IS NULL OR rating BETWEEN 1 AND 5",
                         name: "recruitment_internship_evaluations_rating"
  end
end
