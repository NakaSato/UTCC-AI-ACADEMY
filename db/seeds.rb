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

  puts "Seeded #{User.count} users — student 2011071730001, instructor 2011071730801, " \
       "admin 2011071730802; password utcc2026 for all"
end
