class CreateFeatureSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :feature_settings do |t|
      t.string :key, null: false
      t.string :scope, null: false, default: "global"
      t.boolean :enabled, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :feature_settings, %i[key scope], unique: true
  end
end
