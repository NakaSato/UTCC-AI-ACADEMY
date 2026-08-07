class CreateRecruitmentCandidateResumeAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :recruitment_candidate_resume_analyses do |t|
      t.references :candidate_profile, null: false, foreign_key: true, index: false
      t.references :requested_by, null: false, foreign_key: { to_table: :users }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.string :provider, null: false
      t.string :source_label, null: false
      t.text :uncertainty, null: false
      t.jsonb :source_context, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.datetime :generated_at, null: false
      t.datetime :reviewed_at
      t.datetime :applied_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_candidate_resume_analyses, :candidate_profile_id
    add_index :recruitment_candidate_resume_analyses, :requested_by_id
    add_index :recruitment_candidate_resume_analyses, :reviewed_by_id
    add_index :recruitment_candidate_resume_analyses, [ :candidate_profile_id, :generated_at ],
              name: "recruitment_resume_analyses_newest"
    add_check_constraint :recruitment_candidate_resume_analyses,
                         "status IN ('pending', 'reviewed', 'applied', 'rejected')",
                         name: "recruitment_resume_analyses_status"

    create_table :recruitment_candidate_resume_findings do |t|
      t.references :analysis, null: false, foreign_key: { to_table: :recruitment_candidate_resume_analyses }, index: false
      t.references :applied_fact, foreign_key: { to_table: :candidate_profile_facts }, index: false
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: false
      t.string :kind, null: false
      t.string :title, null: false
      t.text :detail, null: false, default: ""
      t.text :evidence, null: false, default: ""
      t.string :source_type, null: false
      t.decimal :confidence, null: false, default: 0.0, precision: 4, scale: 3
      t.boolean :inferred, null: false, default: false
      t.string :status, null: false, default: "pending"
      t.datetime :reviewed_at
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :recruitment_candidate_resume_findings, :analysis_id
    add_index :recruitment_candidate_resume_findings, :applied_fact_id
    add_index :recruitment_candidate_resume_findings, :reviewed_by_id
    add_check_constraint :recruitment_candidate_resume_findings,
                         "kind IN ('skill', 'tool', 'experience', 'seniority', 'qualification', 'ats_signal', 'skill_gap', 'strength', 'uncertainty')",
                         name: "recruitment_resume_findings_kind"
    add_check_constraint :recruitment_candidate_resume_findings,
                         "source_type IN ('resume_text', 'resume_metadata', 'rules_inference')",
                         name: "recruitment_resume_findings_source_type"
    add_check_constraint :recruitment_candidate_resume_findings,
                         "status IN ('pending', 'edited', 'accepted', 'rejected')",
                         name: "recruitment_resume_findings_status"
    add_check_constraint :recruitment_candidate_resume_findings,
                         "confidence >= 0 AND confidence <= 1",
                         name: "recruitment_resume_findings_confidence"
  end
end
