class CreateInternshipPlacements < ActiveRecord::Migration[8.1]
  def change
    create_table :internship_placements do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.references :student, null: false, foreign_key: { to_table: :users }, index: false
      # Exactly one origin, and both are read-only references. A placement never
      # writes to the application it may have come from — SPEC-0028 owns that.
      t.references :internship_request, foreign_key: true, index: false
      t.references :application, foreign_key: { to_table: :recruitment_internship_applications }, index: false
      t.string :status, null: false, default: "planned"
      t.date :starts_on
      t.date :ends_on
      t.datetime :activated_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :cancellation_reason
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :internship_placements, [ :organization_id, :status ]
    add_index :internship_placements, [ :student_id, :status ]
    add_index :internship_placements, :internship_request_id, unique: true,
              where: "internship_request_id IS NOT NULL"
    add_index :internship_placements, :application_id, unique: true,
              where: "application_id IS NOT NULL"
    add_check_constraint :internship_placements,
                         "status IN ('planned', 'active', 'completed', 'cancelled')",
                         name: "internship_placements_status"
    add_check_constraint :internship_placements,
                         "(internship_request_id IS NULL) != (application_id IS NULL)",
                         name: "internship_placements_one_origin"
    add_check_constraint :internship_placements,
                         "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on",
                         name: "internship_placements_dates"
    add_check_constraint :internship_placements,
                         "status <> 'cancelled' OR (cancellation_reason IS NOT NULL AND cancellation_reason <> '')",
                         name: "internship_placements_cancellation_reason"

    create_table :internship_progress_reports do |t|
      t.references :internship_placement, null: false, foreign_key: true, index: false
      t.references :acknowledged_by, foreign_key: { to_table: :users }, index: false
      # The Monday of the reported week, so "one per week" is a database fact.
      t.date :week_starting_on, null: false
      t.text :activities, null: false
      t.text :outcomes
      t.text :blockers
      t.decimal :hours, precision: 5, scale: 1
      t.datetime :submitted_at, null: false
      t.datetime :acknowledged_at
      t.timestamps
    end

    add_index :internship_progress_reports, [ :internship_placement_id, :week_starting_on ],
              unique: true, name: "internship_progress_reports_one_per_week"
    add_index :internship_progress_reports, :acknowledged_by_id
    add_check_constraint :internship_progress_reports,
                         "hours IS NULL OR (hours >= 0 AND hours <= 168)",
                         name: "internship_progress_reports_hours"
  end
end
