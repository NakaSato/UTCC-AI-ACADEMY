class AddLifecycleStateToCourses < ActiveRecord::Migration[8.1]
  STATES = %w[ draft published archived ].freeze

  def up
    add_column :courses, :lifecycle_state, :string, null: false, default: "draft"
    execute <<~SQL
      UPDATE courses SET lifecycle_state = 'published'
    SQL
    add_check_constraint :courses, "lifecycle_state IN ('draft', 'published', 'archived')",
                        name: "courses_lifecycle_state"
    add_index :courses, :lifecycle_state
  end

  def down
    remove_index :courses, :lifecycle_state
    remove_check_constraint :courses, name: "courses_lifecycle_state"
    remove_column :courses, :lifecycle_state
  end
end
