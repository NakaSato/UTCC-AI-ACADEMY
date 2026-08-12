class CreateInternshipFacultyAssignments < ActiveRecord::Migration[8.1]
  def change
    # Faculty oversight, ADR-0041 decision 2, answered 2026-08-12. Authority is
    # an assignment on one User, not a role and not a second identity store: a
    # role held for teaching a course was never consent to read one student's
    # internship, and the assignment is where that consent is recorded.
    create_table :internship_faculty_assignments do |t|
      t.references :internship_placement, null: false, foreign_key: true, index: false
      t.references :faculty, null: false, foreign_key: { to_table: :users }, index: false
      t.references :assigned_by, null: false, foreign_key: { to_table: :users }, index: false
      t.string :status, null: false, default: "active"
      t.datetime :revoked_at
      t.timestamps
    end

    # One supervisor at a time. A revoked assignment stays as evidence of who
    # could read what and when, so the uniqueness is on the active one only.
    add_index :internship_faculty_assignments, :internship_placement_id, unique: true,
              where: "status = 'active'", name: "internship_faculty_assignments_one_active"
    add_index :internship_faculty_assignments, [ :faculty_id, :status ]
    add_index :internship_faculty_assignments, :assigned_by_id
    add_check_constraint :internship_faculty_assignments,
                         "status IN ('active', 'revoked')",
                         name: "internship_faculty_assignments_status"
    add_check_constraint :internship_faculty_assignments,
                         "status <> 'revoked' OR revoked_at IS NOT NULL",
                         name: "internship_faculty_assignments_revoked_at"

    # The supervisor's acknowledgement is its own pair of columns. The existing
    # one belongs to the company, and two different people confirming they read
    # the same week must not overwrite each other — ADR-0041 decision 2 gives
    # faculty no authority over the company's record.
    add_reference :internship_progress_reports, :faculty_acknowledged_by,
                  foreign_key: { to_table: :users }, index: false
    add_column :internship_progress_reports, :faculty_acknowledged_at, :datetime
    add_index :internship_progress_reports, :faculty_acknowledged_by_id
  end
end
