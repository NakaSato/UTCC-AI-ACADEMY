class AddStudentIdToUsers < ActiveRecord::Migration[8.1]
  # Students sign in with their student ID, so it stops being derived from the
  # email address and becomes the account's own identifier. email_address turns
  # optional: sign-up no longer asks for one.
  def up
    add_column :users, :student_id, :string

    # Accounts predating this carry their identifier in the local part of the
    # address — the only student ID they have, so it becomes the column value.
    #
    # split_part is Postgres; this read instr() while the app was on SQLite, which
    # Postgres does not have. Rewritten rather than made adapter-aware, because
    # the app has one adapter and a migration nobody can run is worse than one
    # that only runs on the database we ship.
    execute <<~SQL.squish
      UPDATE users
      SET student_id = split_part(email_address, '@', 1)
      WHERE student_id IS NULL AND email_address IS NOT NULL
    SQL

    change_column_null :users, :student_id, false
    add_index :users, :student_id, unique: true

    change_column_null :users, :email_address, true
  end

  def down
    # Rebuild an address for every account that has none, so the NOT NULL below
    # can go back on.
    execute <<~SQL.squish
      UPDATE users
      SET email_address = student_id || '@utcc.ac.th'
      WHERE email_address IS NULL
    SQL

    change_column_null :users, :email_address, false
    remove_index :users, :student_id
    remove_column :users, :student_id
  end
end
