# Seeds must stay idempotent: bin/ci runs `db:seed:replant` against the test
# database on every pass.
#
# Sign-in authenticates on student_id, and sign-up collects no email — these
# accounts carry none either.
#
# Shared password, so this is fenced to development and test.
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

  puts "Seeded #{User.count} users — student 2011071730001, instructor 2011071730801, " \
       "admin 2011071730802; password utcc2026 for all"
  puts "Seeded #{TopicCompletion.count} topic completions"
end
