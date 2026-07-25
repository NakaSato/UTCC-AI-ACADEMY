class AddRoleToUsers < ActiveRecord::Migration[8.1]
  # Sign-up only ever produces a student; instructor and admin are granted from
  # the admin screen. String-backed rather than an integer so the value reads the
  # same in seeds, in the console and in schema.rb, and so reordering the list
  # later cannot silently reassign anyone.
  def change
    add_column :users, :role, :string, null: false, default: "student"
  end
end
