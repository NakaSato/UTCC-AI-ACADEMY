class CreateLessonIntegritySettings < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_integrity_settings do |t|
      t.references :course, null: false, foreign_key: true
      t.string :topic_key, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :lesson_integrity_settings, %i[ course_id topic_key ], unique: true
  end
end
