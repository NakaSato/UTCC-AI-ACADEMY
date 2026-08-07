class CreateRecruitmentInternshipProgramSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_internship_program_suggestions do |t|
      t.references :program, null: false, foreign_key: { to_table: :recruitment_internship_programs }, index: false
      t.references :requested_by, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.string :kind, null: false
      t.text :content, null: false
      t.string :provider, null: false
      t.string :model
      t.text :source_label, null: false
      t.text :uncertainty, null: false
      t.jsonb :source_context, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.datetime :generated_at, null: false
      t.datetime :reviewed_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_internship_program_suggestions, [ :program_id, :kind ],
              unique: true, where: "status IN ('pending', 'edited')",
              name: "recruitment_internship_suggestions_one_actionable"
    add_check_constraint :recruitment_internship_program_suggestions,
                         "kind IN ('description', 'learning_roadmap', 'mentor_guide', 'evaluation_criteria', 'final_project')",
                         name: "recruitment_internship_suggestions_kind"
    add_check_constraint :recruitment_internship_program_suggestions,
                         "status IN ('pending', 'edited', 'accepted', 'rejected')",
                         name: "recruitment_internship_suggestions_status"
  end
end
