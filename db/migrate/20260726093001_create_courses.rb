class CreateCourses < ActiveRecord::Migration[8.1]
  # The taxonomy that everything else already referenced by string. Until now a
  # course was a code in a frozen constant and a topic was a "<module>-<position>"
  # key, both validated by TopicCompletion so they could not drift; these tables
  # are what those validations become.
  #
  # Copy is deliberately NOT here. Every word a human reads still lives in
  # config/locales, joined to a course by its code and to a topic by its position
  # — see the placeholder-content notes in CLAUDE.md. What moves into the database
  # is identity, taxonomy and numbers.
  #
  # Modules and topics belong to no course on purpose: every course reuses the one
  # syllabus, exactly as the constants did. Giving each course its own modules
  # needs sixteen sets of content that nobody has written, which is a content job
  # rather than a modelling one. `course_modules.course_id` is the column to add
  # on the day that content exists.

  # code, credits, rating, projects, hours, level, core, certificate, tags, learners
  COURSES = [
    [ "AI1101", 3, "4.8", 6, 42, "beginner",     true,  true,  %w[ core popular ],  "1,240" ],
    [ "AI1102", 3, "4.7", 9, 55, "beginner",     true,  true,  %w[ core popular ],  "980" ],
    [ "AI2201", 3, "4.6", 8, 60, "intermediate", true,  true,  %w[ core ml ],       "612" ],
    [ "AI2105", 2, "4.9", 5, 24, "beginner",     false, true,  %w[ popular genai ], "1,510" ],
    [ "AI2108", 3, "4.5", 7, 38, "intermediate", false, false, %w[ data ],          "445" ],
    [ "AI3301", 3, "4.6", 6, 50, "advanced",     false, true,  %w[ ml ],            "288" ],
    [ "AI2210", 2, "4.8", 4, 20, "beginner",     false, false, %w[ popular genai ], "870" ],
    [ "AI2402", 2, "4.4", 3, 18, "beginner",     false, false, %w[ ethics ],        "520" ]
  ].freeze

  # knowledge units, then one [kind, minutes] pair per topic, in the order the
  # topic names appear under `course.modules` in the locale files. That order is
  # load-bearing: the position is half of a topic's key.
  MODULES = [
    [ 12, [ [ "theory", 8 ],  [ "theory", 10 ], [ "exercise", 15 ] ] ],
    [ 18, [ [ "theory", 9 ],  [ "theory", 12 ], [ "mix", 14 ], [ "code", 20 ] ] ],
    [ 22, [ [ "code", 18 ],   [ "code", 24 ] ] ],
    [ 15, [ [ "theory", 11 ], [ "exercise", 16 ] ] ],
    [ 14, [ [ "theory", 12 ], [ "project", 40 ] ] ],
    [ 10, [ [ "theory", 10 ], [ "theory", 12 ] ] ]
  ].freeze

  def up
    create_table :courses do |t|
      t.string  :code, null: false
      t.integer :position, null: false
      t.integer :credits, null: false
      t.string  :rating, null: false
      t.integer :projects, null: false
      t.integer :hours, null: false
      t.string  :level, null: false
      t.boolean :core, null: false, default: false
      t.boolean :certificate, null: false, default: false
      # The filter chips on the catalog. A short list per course, read whole and
      # never queried across, so a json column beats a join table here.
      t.json    :tags, null: false, default: []
      # A display string ("1,240"), not a count — nothing enrols yet.
      t.string  :learners, null: false

      t.timestamps
    end

    add_index :courses, :code, unique: true
    add_index :courses, :position, unique: true

    create_table :course_modules do |t|
      t.integer :number, null: false
      t.integer :units, null: false

      t.timestamps
    end

    add_index :course_modules, :number, unique: true

    create_table :topics do |t|
      t.references :course_module, null: false, foreign_key: true
      t.integer :position, null: false
      # `key` is "<module number>-<position>" — derived, but stored because it is
      # the public identifier: it is what /lesson?topic= carries and what a
      # completion is filed under.
      t.string  :key, null: false
      t.string  :kind, null: false
      t.integer :minutes, null: false

      t.timestamps
    end

    add_index :topics, :key, unique: true
    add_index :topics, %i[ course_module_id position ], unique: true

    seed
  end

  def down
    drop_table :topics
    drop_table :course_modules
    drop_table :courses
  end

  private
    # Reference data, so the migration writes it rather than db/seeds.rb — seeds
    # are fenced to Rails.env.local? and production would otherwise come up with
    # an empty catalog.
    def seed
      now = Time.current
      courses = table("courses")
      modules = table("course_modules")
      topics  = table("topics")

      courses.insert_all(
        COURSES.each_with_index.map do |(code, credits, rating, projects, hours,
                                         level, core, certificate, tags, learners), index|
          { code:, position: index + 1, credits:, rating:, projects:, hours:, level:,
            core:, certificate:, tags:, learners:, created_at: now, updated_at: now }
        end
      )

      modules.insert_all(
        MODULES.each_with_index.map do |(units, _topics), index|
          { number: index + 1, units:, created_at: now, updated_at: now }
        end
      )

      module_ids = modules.pluck(:number, :id).to_h

      topics.insert_all(
        MODULES.each_with_index.flat_map do |(_units, entries), index|
          number = index + 1

          entries.each_with_index.map do |(kind, minutes), position|
            { course_module_id: module_ids.fetch(number), position: position + 1,
              key: "#{number}-#{position + 1}", kind:, minutes:,
              created_at: now, updated_at: now }
          end
        end
      )
    end

    # Throwaway classes rather than Course and Topic: a migration has to keep
    # working when the app's models move on without it.
    def table(name) = Class.new(ActiveRecord::Base) { self.table_name = name }
end
