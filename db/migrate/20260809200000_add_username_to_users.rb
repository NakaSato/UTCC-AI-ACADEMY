class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  # A console account has no student ID to be identified by, so the column that
  # was every account's name becomes one of three — see User#identifier. The
  # index stays unique; the column is now nullable, and NULLs do not collide.
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true

    change_column_null :users, :student_id, true
  end
end
