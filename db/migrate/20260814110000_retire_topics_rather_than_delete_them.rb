class RetireTopicsRatherThanDeleteThem < ActiveRecord::Migration[8.1]
  def change
    # When a lesson left a syllabus, rather than whether it did.
    #
    # `topic.destroy` has never had a safe outcome: `topic_completions` and
    # `prior_knowledges` are `dependent: :destroy`, so it erases what learners
    # finished, while `submissions` and `proctor_events` hold a foreign key, so it
    # fails on the constraint. ADR-0055 chose retirement over both — the row
    # stays, stops being offered, and stops counting toward a denominator, so a
    # completion and an integrity case can still say which lesson they were about.
    add_column :topics, :retired_at, :datetime
  end
end
