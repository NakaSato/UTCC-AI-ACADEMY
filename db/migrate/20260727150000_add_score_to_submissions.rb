class AddScoreToSubmissions < ActiveRecord::Migration[8.1]
  # What the server made of an attempt, beyond whether it passed. An integer
  # percentage: the share of the step's criteria that matched.
  #
  # The granularity was already there and thrown away — `grade_code` computes one
  # boolean per `LessonContent::CHECKS` entry so the page can light its list, and
  # kept none of it. This is that, kept. A quiz is one right answer, so its score
  # is honestly 0 or 100.
  #
  # NULLABLE ON PURPOSE, and deliberately not backfilled. A row written before
  # this column existed was graded pass/fail and nothing more; deriving
  # `passed ? 100 : 0` for it would invent exactly the kind of measured-looking
  # number this change exists to remove. Unscored rows do not vote in the
  # average — see InstructorReport#average_score.
  def change
    add_column :submissions, :score, :integer
  end
end
