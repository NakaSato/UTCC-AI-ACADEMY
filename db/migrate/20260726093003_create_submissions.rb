class CreateSubmissions < ActiveRecord::Migration[8.1]
  # What a student actually sent, and what the server made of it. This is the
  # table that lets grading move off the browser: until now the answer key and
  # the passing regexes shipped in the page and `POST /lesson/complete` believed
  # whatever it was told, because there was nowhere to put the work itself.
  #
  # One row per attempt, not per topic. A topic_completion is the outcome and
  # there is exactly one; a submission is the trying, and there are as many as
  # the student needs. Keeping the failures is the point — "share failing on
  # first attempt" is the one figure the instructor screen fabricates, and these
  # rows are what will make it true.
  #
  # `answer` holds what was sent: the option index for a quiz, the source for a
  # coding task. Text for both, since a quiz answer is four bytes and giving it
  # its own column would only make the grader ask which one to read.
  def change
    create_table :submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.string  :kind, null: false
      t.text    :answer, null: false
      t.boolean :passed, null: false, default: false

      t.timestamps
    end

    # A learner's attempts at one task, newest last — what the lesson screen
    # would show and what "how many tries did this take" counts.
    add_index :submissions, %i[ user_id topic_id kind ]
    # Across learners: how a task is going, which is the instructor's cut.
    add_index :submissions, %i[ topic_id kind passed ]
  end
end
