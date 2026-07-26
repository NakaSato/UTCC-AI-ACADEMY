class CreateProctorEvents < ActiveRecord::Migration[8.1]
  # What the proctor sees, kept. The score itself is still derived — an event's
  # weight lives in Proctoring, so re-weighting an incident kind is a deploy,
  # not a migration — and `reviewed_at` is what "closing a case" writes: a case
  # is a learner's unreviewed events, and there is no case row to close.
  #
  # The trust boundary is the same one grading used to have, pointed the other
  # way: the browser reports its own incidents, and forging evidence against
  # yourself is not a threat worth code. What the table changes is that the
  # report no longer dies with the page.
  def change
    create_table :proctor_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.string :kind, null: false
      t.datetime :occurred_at, null: false
      t.datetime :reviewed_at

      t.timestamps
    end

    # A case is a learner's unreviewed events; the admin tab groups on exactly
    # this pair.
    add_index :proctor_events, %i[ user_id reviewed_at ]
    add_index :proctor_events, %i[ user_id occurred_at ]
  end
end
