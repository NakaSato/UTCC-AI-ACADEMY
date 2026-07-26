class AddCourseAndTopicToTopicCompletions < ActiveRecord::Migration[8.1]
  # What the string columns were standing in for. `course_code` and `topic_key`
  # were validated against the placeholder taxonomy precisely because the database
  # could not enforce them; now it can, so the validations become foreign keys and
  # the strings go.
  #
  # The two invariants this table carries have to survive the swap intact: one row
  # per learner per topic, and every row naming a course and topic that exist. The
  # unique index moves across with the columns, and the foreign keys are what make
  # the second one true by construction rather than by validation.
  def up
    add_reference :topic_completions, :course, foreign_key: true
    add_reference :topic_completions, :topic, foreign_key: true

    backfill

    # Only enforced after the backfill, or existing rows would fail the check on
    # the way in.
    change_column_null :topic_completions, :course_id, false
    change_column_null :topic_completions, :topic_id, false

    remove_index :topic_completions, %i[ user_id course_code topic_key ]
    add_index :topic_completions, %i[ user_id course_id topic_id ], unique: true

    remove_column :topic_completions, :course_code
    remove_column :topic_completions, :topic_key
  end

  def down
    add_column :topic_completions, :course_code, :string
    add_column :topic_completions, :topic_key, :string

    execute <<~SQL.squish
      UPDATE topic_completions
         SET course_code = (SELECT code FROM courses WHERE courses.id = topic_completions.course_id),
             topic_key   = (SELECT key  FROM topics  WHERE topics.id  = topic_completions.topic_id)
    SQL

    change_column_null :topic_completions, :course_code, false
    change_column_null :topic_completions, :topic_key, false

    remove_index :topic_completions, %i[ user_id course_id topic_id ]
    add_index :topic_completions, %i[ user_id course_code topic_key ], unique: true

    remove_reference :topic_completions, :course, foreign_key: true
    remove_reference :topic_completions, :topic, foreign_key: true
  end

  private
    # A row whose code or key no longer resolves would fail the NOT NULL below and
    # abort the migration — which is the right outcome. The validations were meant
    # to make it impossible, and if one slipped through, that is worth stopping
    # for rather than dropping the row on the floor.
    def backfill
      execute <<~SQL.squish
        UPDATE topic_completions
           SET course_id = (SELECT id FROM courses WHERE courses.code = topic_completions.course_code),
               topic_id  = (SELECT id FROM topics  WHERE topics.key   = topic_completions.topic_key)
      SQL
    end
end
