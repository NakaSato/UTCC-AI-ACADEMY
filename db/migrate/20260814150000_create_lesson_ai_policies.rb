class CreateLessonAiPolicies < ActiveRecord::Migration[8.1]
  def change
    # What a student may do with an AI assistant in one lesson.
    #
    # An AI academy that proctors its lessons and says nothing about AI use is
    # asking students to guess where the line is. This is the line, written down
    # per lesson: three kinds of use, three stances, and a default that says
    # "disclose it" rather than "anything goes".
    #
    # Deliberately a sibling of `lesson_integrity_settings` rather than a column
    # on it: that setting decides whether the proctor log is *shown*, and this
    # decides what is *allowed*. Neither implies the other.
    create_table :lesson_ai_policies do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.string :topic_key, null: false
      t.string :use_key, null: false
      t.string :stance, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps

      t.index [ :course_id, :topic_key, :use_key ], unique: true, name: "index_lesson_ai_policies_on_lesson_and_use"
      t.check_constraint "stance IN ('allowed', 'disclose', 'forbidden')", name: "lesson_ai_policies_stance"
    end
  end
end
