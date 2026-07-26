# Seeds must stay idempotent: bin/ci runs `db:seed:replant` against the test
# database on every pass.
#
# Sign-in authenticates on student_id, and sign-up collects no email — these
# accounts carry none either.

# ---- The catalog taxonomy ---------------------------------------------------
# Deliberately outside the fence below: these rows carry no credentials, and
# `db:seed` should be able to put the catalog back in any environment.
#
# This is one of three copies of the same taxonomy, and they must agree:
#   db/migrate/…_create_courses.rb   writes them once, and is what production has
#   db/seeds.rb                      this — restores them after db:seed:replant
#                                    truncates every table, which bin/ci does
#   test/fixtures/{courses,course_modules,topics}.yml   the suite's copy
# taxonomy_test.rb asserts the shape the app depends on, so a row added to one
# copy and not the others fails rather than quietly shortening a syllabus.
courses = [
  [ "AI1101", 3, "4.8", 6, 42, "beginner",     true,  true,  %w[ core popular ],  "1,240" ],
  [ "AI1102", 3, "4.7", 9, 55, "beginner",     true,  true,  %w[ core popular ],  "980" ],
  [ "AI2201", 3, "4.6", 8, 60, "intermediate", true,  true,  %w[ core ml ],       "612" ],
  [ "AI2105", 2, "4.9", 5, 24, "beginner",     false, true,  %w[ popular genai ], "1,510" ],
  [ "AI2108", 3, "4.5", 7, 38, "intermediate", false, false, %w[ data ],          "445" ],
  [ "AI3301", 3, "4.6", 6, 50, "advanced",     false, true,  %w[ ml ],            "288" ],
  [ "AI2210", 2, "4.8", 4, 20, "beginner",     false, false, %w[ popular genai ], "870" ],
  [ "AI2402", 2, "4.4", 3, 18, "beginner",     false, false, %w[ ethics ],        "520" ]
]

courses.each_with_index do |(code, credits, rating, projects, hours, level, core, certificate, tags, learners), index|
  Course.find_or_initialize_by(code:).update!(
    position: index + 1, credits:, rating:, projects:, hours:, level:,
    core:, certificate:, tags:, learners:
  )
end

# knowledge units, then one [kind, minutes] pair per topic — in the order the
# topic names appear under `course.modules` in the locale files, since a topic's
# position is half of its key.
modules = [
  [ 12, [ [ "theory", 8 ],  [ "theory", 10 ], [ "exercise", 15 ] ] ],
  [ 18, [ [ "theory", 9 ],  [ "theory", 12 ], [ "mix", 14 ], [ "code", 20 ] ] ],
  [ 22, [ [ "code", 18 ],   [ "code", 24 ] ] ],
  [ 15, [ [ "theory", 11 ], [ "exercise", 16 ] ] ],
  [ 14, [ [ "theory", 12 ], [ "project", 40 ] ] ],
  [ 10, [ [ "theory", 10 ], [ "theory", 12 ] ] ]
]

modules.each_with_index do |(units, topics), index|
  number = index + 1
  course_module = CourseModule.find_or_initialize_by(number:)
  course_module.update!(units:)

  topics.each_with_index do |(kind, minutes), position|
    Topic.find_or_initialize_by(key: Topic.key_for(number, position + 1))
         .update!(course_module:, position: position + 1, kind:, minutes:)
  end
end

# The syllabus is memoised, and this process may have read it before the rows
# above existed.
Syllabus.reload!

puts "Seeded #{Course.count} courses and #{Topic.count} topics across #{CourseModule.count} modules"

# ---- The landing page's cards -----------------------------------------------
# Outside the fence for the same reason as the catalog: no credentials, and a
# landing page with no cards on it is not a landing page. One of three copies
# that must agree — the CreateLandingCards migration, this, and
# test/fixtures/landing_cards.yml.
#
# Copy is NOT here. A card carries its slug, its order and (for a track or an
# event) its own attributes; the words are `landing.*` in the locale files, with
# a `landing_texts` override in front of them.
landing_cards = {
  "topics" => %w[ what_is_ai prompting machine_learning build_apps ethics business ].map { [ it ] },
  # key, level, weeks — nil weeks where the track is open-ended.
  "tracks" => [
    [ "beginners", "beginner", 4 ], [ "engineering", "beginner", 6 ],
    [ "first_project", "intermediate", 8 ], [ "data_ml", "intermediate", 8 ],
    [ "agents", "advanced", 10 ], [ "research", "advanced", nil ]
  ],
  "shares" => %w[ chatbot free_tools neural_net ].map { [ it ] },
  # key, then the calendar date where there is one.
  "events" => [ [ "study_jam" ], [ "workshop", "2026-08-08" ], [ "show_and_tell" ] ],
  "faqs" => %w[ no_background homework share_project other_faculties ].map { [ it ] }
}

landing_cards.each do |collection, rows|
  rows.each_with_index do |row, index|
    card = LandingCard.find_or_initialize_by(collection:, key: row.first)
    attributes = { position: index + 1 }

    case collection
    in "tracks" then attributes.merge!(level: row[1], weeks: row[2])
    in "events" then attributes[:starts_on] = row[1]
    else nil
    end

    card.update!(attributes)
  end
end

Landing.forget_cards

puts "Seeded #{LandingCard.count} landing cards across #{landing_cards.size} collections"

# ---- Demo accounts ----------------------------------------------------------
# Shared password, so this half is fenced to development and test.
if Rails.env.local?
  # One account per role, so every gate can be walked through by hand. `role` is
  # left off the students: the column defaults to "student".
  {
    "2011071730001" => { name: "ณฐพร จิรวัฒนกุล", faculty: "บริหารธุรกิจ", study_year: 2 },
    "2011071730002" => { name: "สมหญิง ใจดี", faculty: "วิศวกรรมศาสตร์", study_year: 1 },
    "2011071730801" => { name: "ผศ. ดร. วิชัย ตั้งมั่น", faculty: "วิศวกรรมศาสตร์", role: "instructor" },
    "2011071730802" => { name: "ผู้ดูแลระบบ", faculty: "วิศวกรรมศาสตร์", role: "admin" }
  }.each do |student_id, attributes|
    # find_or_initialize rather than find_or_create: the password is set on every
    # run, so re-seeding an existing demo account resets it instead of leaving
    # whatever it was created with.
    user = User.find_or_initialize_by(student_id: student_id)
    user.assign_attributes(attributes)
    # "password" itself is rejected now — see User::COMMON_PASSWORDS.
    user.password = "utcc2026"
    user.save!
  end

  # Progress is counted off topic_completions now, so without these the demo
  # student opens onto empty progress bars and no streak. Spread over the last
  # few days on purpose: a streak and a contribution grid need more than one date
  # to show anything.
  demo = User.find_by(student_id: "2011071730001")
  keys = Syllabus.topic_keys

  # Four topics of AI1101, the last three on consecutive days up to today, and
  # the coding-task half of two of them.
  [ 6, 2, 1, 0 ].each_with_index do |days_ago, index|
    TopicCompletion.record(user: demo, course_code: "AI1101", topic_key: keys[index],
                           kind: index < 2 ? :applied : :learned, at: days_ago.days.ago)
  end

  # A second student, further along, so the leaderboard has someone to rank
  # against and /admin has more than one row worth looking at.
  rival = User.find_by(student_id: "2011071730002")
  keys.first(7).each_with_index do |key, index|
    TopicCompletion.record(user: rival, course_code: "AI1102", topic_key: key,
                           kind: :learned, at: index.days.ago)
  end

  # ---- A section to teach ----------------------------------------------------
  # The Teaching console is a report on a section, and the leaderboard ranks
  # within one, so without this both screens have nothing to be about. Five more
  # students than the two above, because a roster of two demonstrates nothing.
  section = Section.find_or_initialize_by(course: Course.find_by!(code: "AI1101"), term: "1/2569", code: "BA-2")
  section.update!(instructor: User.find_by!(student_id: "2011071730801"))

  cohort = {
    "2011071730003" => [ "ปัณณธร สุวรรณเวช", 9 ],
    "2011071730004" => [ "ญาณิศา กิตติวัฒน์", 6 ],
    "2011071730005" => [ "กันตพัฒน์ วรพงศ์", 4 ],
    "2011071730006" => [ "ศุภกร ตันติเวช", 1 ],
    "2011071730007" => [ "พิชญา มณีรัตน์", 0 ]
  }

  cohort.each do |student_id, (name, finished)|
    student = User.find_or_initialize_by(student_id:)
    student.assign_attributes(name:, faculty: "บริหารธุรกิจ", study_year: 2)
    student.password = "utcc2026"
    student.save!

    # Some progress each, so the roster is a spread rather than a flat zero.
    Syllabus.topic_keys.first(finished).each_with_index do |key, index|
      TopicCompletion.record(user: student, course_code: "AI1101", topic_key: key,
                             kind: :learned, at: (finished - index).days.ago)
    end
  end

  ([ demo, rival ] + User.where(student_id: cohort.keys).to_a).each do |student|
    Enrollment.find_or_create_by!(section:, user: student)
  end

  # The hard-topics panel counts first attempts that failed, so it needs some.
  # Every second student gets one wrong before getting it right — which is what
  # makes a topic look hard without making it look unpassable.
  course = Course.find_by!(code: "AI1101")
  section.students.each_with_index do |student, index|
    next unless index.even?

    Topic.where(key: Syllabus.keys_in(1).first(2)).each do |topic|
      next if Submission.exists?(user: student, topic:, kind: "quiz")

      Submission.create!(user: student, course:, topic:, kind: "quiz",
                         answer: (LessonContent::CORRECT_OPTION + 1).to_s, passed: false)
    end
  end

  # A couple of integrity cases, so the admin tab has something real to show.
  # Deterministic and idempotent: skip any learner who already has events.
  course = Course.find_by!(code: "AI1101")
  {
    "2011071730006" => %w[ paste capture blur blur ],
    "2011071730005" => %w[ blur paste_small ]
  }.each do |student_id, kinds|
    student = User.find_by!(student_id:)
    next if ProctorEvent.exists?(user: student)

    kinds.each_with_index do |kind, index|
      ProctorEvent.create!(user: student, course:, topic: Topic.find_by!(key: "1-1"),
                           kind:, occurred_at: (kinds.size - index).hours.ago)
    end
  end

  puts "Seeded 1 section (#{section.label}) with #{section.students.count} students " \
       "and #{Submission.count} submissions"

  puts "Seeded #{User.count} users — student 2011071730001, instructor 2011071730801, " \
       "admin 2011071730802; password utcc2026 for all"
  puts "Seeded #{TopicCompletion.count} topic completions"
end
