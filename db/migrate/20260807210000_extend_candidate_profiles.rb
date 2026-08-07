class ExtendCandidateProfiles < ActiveRecord::Migration[8.1]
  def change
    change_table :candidate_profiles do |t|
      t.string :portfolio_url
      t.string :github_url
      t.string :linkedin_url
      t.integer :salary_expectation_min
      t.integer :salary_expectation_max
      t.string :salary_currency, null: false, default: "THB", limit: 3
      t.boolean :application_data_reuse_consent, null: false, default: false
      t.datetime :consent_given_at
      t.integer :lock_version, null: false, default: 0
    end

    add_check_constraint :candidate_profiles,
                         "salary_expectation_min IS NULL OR salary_expectation_min >= 0",
                         name: "candidate_profiles_salary_min"
    add_check_constraint :candidate_profiles,
                         "salary_expectation_max IS NULL OR salary_expectation_max >= 0",
                         name: "candidate_profiles_salary_max"
    add_check_constraint :candidate_profiles,
                         "salary_expectation_min IS NULL OR salary_expectation_max IS NULL OR salary_expectation_min <= salary_expectation_max",
                         name: "candidate_profiles_salary_range"

    create_table :candidate_profile_facts do |t|
      t.references :candidate_profile, null: false, foreign_key: true, index: false
      t.string :kind, null: false
      t.string :title, null: false, default: ""
      t.string :organization, null: false, default: ""
      t.text :detail, null: false, default: ""
      t.string :source, null: false, default: "self_reported"
      t.decimal :confidence, null: false, precision: 4, scale: 3, default: 1.0
      t.integer :position, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :candidate_profile_facts, [ :candidate_profile_id, :kind, :position ],
              name: "candidate_profile_facts_order"
    add_check_constraint :candidate_profile_facts,
                         "kind IN ('education', 'experience', 'skill', 'certification', 'language')",
                         name: "candidate_profile_facts_kind"
    add_check_constraint :candidate_profile_facts,
                         "source IN ('self_reported', 'document_extracted', 'human_reviewed')",
                         name: "candidate_profile_facts_source"
    add_check_constraint :candidate_profile_facts,
                         "confidence BETWEEN 0 AND 1",
                         name: "candidate_profile_facts_confidence"
  end
end
