class CreateSections < ActiveRecord::Migration[8.1]
  # The concept `users` never had. The leaderboard needs something to rank
  # within, and the Teaching console needs to know whose roster it is showing —
  # both have been fabricating that, because "หมู่เรียน BA-2" was a string in a
  # locale file rather than a thing anyone belonged to.
  #
  # A section is one course, one term, one instructor. Students reach it through
  # `enrollments`, which is a join and nothing more: no grade, no state. What a
  # learner has done is already in topic_completions and submissions, and putting
  # a copy of it here would give the two a way to disagree.
  #
  # `instructor_id` is nullable on purpose — a section can be timetabled before
  # anyone is assigned to teach it, and a nullable column is honest about that
  # where a placeholder instructor would not be.
  def change
    create_table :sections do |t|
      t.references :course, null: false, foreign_key: true
      t.references :instructor, foreign_key: { to_table: :users }
      t.string :code, null: false
      t.string :term, null: false

      t.timestamps
    end

    # One "BA-2" per course per term, and the natural lookup for a course page.
    add_index :sections, %i[ course_id term code ], unique: true

    create_table :enrollments do |t|
      t.references :section, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # A student is in a section once. The reverse index is what the roster reads.
    add_index :enrollments, %i[ section_id user_id ], unique: true
    add_index :enrollments, %i[ user_id section_id ]
  end
end
