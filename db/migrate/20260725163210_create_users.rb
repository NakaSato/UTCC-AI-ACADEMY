class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      # Optional profile shown alongside community posts.
      t.string :faculty
      t.integer :study_year

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
