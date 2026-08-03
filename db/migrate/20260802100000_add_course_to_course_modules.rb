class AddCourseToCourseModules < ActiveRecord::Migration[8.1]
  DEFAULT_COURSE = "AI1101"

  def up
    add_reference :course_modules, :course, foreign_key: true

    execute <<~SQL.squish
      UPDATE course_modules
         SET course_id = (SELECT id FROM courses WHERE courses.code = '#{DEFAULT_COURSE}')
    SQL

    unresolved = select_value("SELECT COUNT(*) FROM course_modules WHERE course_id IS NULL").to_i
    raise "Cannot backfill course_modules.course_id: #{unresolved} module(s) have no #{DEFAULT_COURSE} course" if unresolved.positive?

    change_column_null :course_modules, :course_id, false
    remove_index :course_modules, :number
    add_index :course_modules, %i[ course_id number ], unique: true
  end

  def down
    extra_courses = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*) FROM course_modules
       WHERE course_id <> (SELECT id FROM courses WHERE courses.code = '#{DEFAULT_COURSE}')
    SQL
    raise "Cannot remove course scoping while non-#{DEFAULT_COURSE} modules exist" if extra_courses.positive?

    remove_index :course_modules, %i[ course_id number ]
    add_index :course_modules, :number, unique: true
    remove_reference :course_modules, :course, foreign_key: true
  end
end
