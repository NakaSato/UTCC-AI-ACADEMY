class CreatePriorKnowledges < ActiveRecord::Migration[8.1]
  # A learner's prior-knowledge assertion is deliberately separate from an
  # academy completion. The foreign keys keep the assertion course-scoped, and
  # the unique key makes repeated clicks and concurrent requests idempotent.
  def change
    create_table :prior_knowledges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.datetime :marked_at, null: false

      t.timestamps
    end

    add_index :prior_knowledges, %i[ user_id course_id topic_id ], unique: true
    add_index :prior_knowledges, %i[ user_id course_id ]
  end
end
