class CreateTopicCompletions < ActiveRecord::Migration[8.1]
  # The first thing the app remembers about learning. Everything the progress
  # screens claim — streak, XP, the contribution grid, which courses are in
  # flight — is counted off these rows.
  #
  # A topic is identified by course code and a "<module>-<position>" key rather
  # than by foreign keys: there are no Course or Topic tables yet, and this table
  # is what makes them worth building. Both halves are validated against the
  # placeholder taxonomy in TopicCompletion, so the strings cannot drift.
  #
  # Learning a topic and applying it are one row, not two: the UI shows them as
  # two bars over the same list of topics, and a topic can never be applied
  # without first being learned.
  def change
    create_table :topic_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :course_code, null: false
      t.string :topic_key, null: false
      t.datetime :learned_at, null: false
      t.datetime :applied_at

      t.timestamps
    end

    # One row per topic per learner — the uniqueness that makes recording a
    # completion idempotent, so a re-run of the exercise cannot inflate a count.
    add_index :topic_completions, %i[ user_id course_code topic_key ], unique: true
    # The streak and the contribution grid both read a learner's rows in date
    # order.
    add_index :topic_completions, %i[ user_id learned_at ]
  end
end
