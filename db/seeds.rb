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
    core:, certificate:, tags:, learners:, lifecycle_state: "published"
  )
end

# Each course owns its module rows. Topic keys remain globally unique: AI1101
# keeps the historic `1-1` shape, while the second curriculum uses keys such as
# `AI1102-1-1` so old URLs and completion records remain stable.
modules = [
  [ 12, [ [ "theory", 8 ],  [ "theory", 10 ], [ "exercise", 15 ] ] ],
  [ 18, [ [ "theory", 9 ],  [ "theory", 12 ], [ "mix", 14 ], [ "code", 20 ] ] ],
  [ 22, [ [ "code", 18 ],   [ "code", 24 ] ] ],
  [ 15, [ [ "theory", 11 ], [ "exercise", 16 ] ] ],
  [ 14, [ [ "theory", 12 ], [ "project", 40 ] ] ],
  [ 10, [ [ "theory", 10 ], [ "theory", 12 ] ] ]
]

curricula = {
  "AI1101" => modules,
  # Deliberately smaller and shaped around Python/data preparation rather than
  # the six-module AI fundamentals syllabus.
  "AI1102" => [
    [ 8,  [ [ "theory", 12 ], [ "exercise", 18 ] ] ],
    [ 12, [ [ "code", 20 ], [ "theory", 15 ], [ "project", 35 ] ] ]
  ]
}

curricula.each do |course_code, course_modules|
  course = Course.find_by!(code: course_code)

  course_modules.each_with_index do |(units, topics), index|
    number = index + 1
    course_module = CourseModule.find_or_initialize_by(course:, number:)
    course_module.update!(units:)

    topics.each_with_index do |(kind, minutes), position|
      key = Topic.key_for(number, position + 1, course_code:)
      Topic.find_or_initialize_by(key:)
           .update!(course_module:, position: position + 1, kind:, minutes:)
    end
  end
end

# The syllabi are memoised, and this process may have read them before the rows
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
  # Two learners, by student ID, the way sign-up makes them.
  {
    "2011071730001" => { name: "ณฐพร จิรวัฒนกุล", faculty: "บริหารธุรกิจ", study_year: 2 },
    "2011071730002" => { name: "สมหญิง ใจดี", faculty: "วิศวกรรมศาสตร์", study_year: 1 }
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

  # And three console accounts, by username, the way /admin makes them. None has
  # a student ID: an instructor has no student card, and a recruiter has no
  # reason to know a thirteen-digit number. The company account carries no role
  # either — company reach is an active OrganizationMembership, never a column on
  # the user (ADR-0024) — so its membership is granted further down.
  #
  # `legacy_student_id` is only for upgrading a database seeded before console
  # accounts existed: the row is found by the ID it used to have, and the ID is
  # then cleared. A fresh database never matches it.
  [
    { username: "wichai", name: "ผศ. ดร. วิชัย ตั้งมั่น", email_address: "wichai@utcc.ac.th",
      faculty: "วิศวกรรมศาสตร์", role: "instructor", legacy_student_id: "2011071730801" },
    { username: "utcc-admin", name: "ผู้ดูแลระบบ", email_address: "admin@utcc.ac.th",
      faculty: "วิศวกรรมศาสตร์", role: "admin", legacy_student_id: "2011071730802" },
    { username: "northstar", name: "ชนิกานต์ พงศ์ธนา", email_address: "recruiter@northstar.co.th",
      legacy_student_id: "2011071730901" }
  ].each do |attributes|
    attributes = attributes.dup
    legacy = attributes.delete(:legacy_student_id)
    user = User.find_by(username: attributes[:username]) ||
           User.find_by(student_id: legacy) ||
           User.new
    user.assign_attributes(attributes.merge(student_id: nil))
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
  Syllabus.topic_keys("AI1102").each_with_index do |key, index|
    TopicCompletion.record(user: rival, course_code: "AI1102", topic_key: key,
                           kind: :learned, at: index.days.ago)
  end

  # ---- A section to teach ----------------------------------------------------
  # The Teaching console is a report on a section, and the leaderboard ranks
  # within one, so without this both screens have nothing to be about. Five more
  # students than the two above, because a roster of two demonstrates nothing.
  section = Section.find_or_initialize_by(course: Course.find_by!(code: "AI1101"), term: "1/2569", code: "BA-2")
  section.update!(instructor: User.find_by!(username: "wichai"))

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
                         answer: (LessonContent::CORRECT_OPTION + 1).to_s, passed: false, score: 0)
      # And then got it right, so the average is of best attempts rather than of
      # one bad one — which is the distinction the tile is making.
      Submission.create!(user: student, course:, topic:, kind: "quiz",
                         answer: LessonContent::CORRECT_OPTION.to_s, passed: true, score: 100)
    end
  end

  # Coding tasks at three depths, so the Teaching console's average lands
  # somewhere honest rather than at 0 or 100. The scores are what `grade_code`
  # would return for source matching one, two and three of its criteria.
  section.students.each_with_index do |student, index|
    topic = Topic.find_by!(key: Syllabus.keys_in(1).first)
    next if Submission.exists?(user: student, topic:, kind: "code")

    met = index % 3 + 1
    Submission.create!(user: student, course:, topic:, kind: "code",
                       answer: "train_test_split(", passed: met == 3,
                       score: (met * 100.0 / 3).round)
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

  # ---- A company to sign in as -----------------------------------------------
  # /console admits three populations and only two of them could be seeded before
  # this: an organization with an active membership is what makes the third one
  # exist. Built the way the app builds it — an admin creates the organization
  # and names an owner — so the demo data matches what the screens produce.
  #
  # The slug is explicit because `derive_slug` parameterizes the name, and a Thai
  # name parameterizes to nothing.
  company = Organization.find_or_initialize_by(slug: "northstar")
  company.update!(name: "บริษัท นอร์ทสตาร์ เทคโนโลยี จำกัด",
                  creator: User.find_by!(username: "utcc-admin"),
                  accepts_internship_requests: true)

  # Owner rather than recruiter: it is the one role that opens both the hiring
  # screens and the business-case workspace, so a single demo account can walk
  # the whole company side.
  recruiter = User.find_by!(username: "northstar")
  company.memberships.find_or_initialize_by(user: recruiter).update!(role: "owner", status: "active")

  puts "Seeded 1 organization (#{company.name}) with #{company.memberships.active.count} active member"

  # ---- One internship, all the way through -----------------------------------
  # SPEC-0041 ships four increments and a fresh database showed none of them: no
  # request to decide, no placement to advance, no week to acknowledge, no
  # supervisor, no file. Every screen was an empty state, which is the one thing
  # a demo cannot demonstrate.
  #
  # Walked through the real APIs rather than written straight into the tables —
  # submit!, approve!, from_request!, activate! — so the seeded rows are the ones
  # the app itself would produce, guards and all. Keyed on the student so a
  # replant finds the request it made last time instead of making another.
  demo_student = User.find_by!(student_id: "2011071730001")
  faculty = User.find_by!(username: "wichai")
  admin = User.find_by!(username: "utcc-admin")

  # A profile with a résumé first, because sharing one is only allowed while the
  # request is open — a student decides what the company may read *before* the
  # company decides. Sharing is a timestamp on the request: SPEC-0041 stores no
  # second copy of the file.
  profile = CandidateProfile.find_or_create_by!(user: demo_student) do |record|
    record.application_data_reuse_consent = true
  end
  unless profile.resume.attached?
    profile.resume.attach(io: StringIO.new("%PDF-1.4 demo résumé"), filename: "resume.pdf",
                          content_type: "application/pdf")
  end

  internship_request = company.internship_requests.find_by(student: demo_student)
  if internship_request.nil?
    internship_request = company.internship_requests.create!(
      student: demo_student,
      motivation: "อยากร่วมงานกับทีมที่วางเส้นทางส่งของจริง และได้เห็นว่าการวัดผลเปลี่ยนการตัดสินใจอย่างไร",
      learning_goals: "การหาเส้นทางที่เหมาะสม การวัดผล และการอ่านข้อมูลปฏิบัติการ"
    )
    internship_request.submit!(actor: demo_student)
    internship_request.share_resume!(actor: demo_student)
    internship_request.approve!(actor: recruiter)
  end

  placement = internship_request.placement ||
              InternshipPlacement.from_request!(internship_request, actor: recruiter)
  placement.activate!(actor: recruiter) if placement.planned?

  if placement.progress_reports.none?
    placement.progress_reports.create!(
      activities: "สำรวจเส้นทางส่งของรอบเย็นทั้งหมด และจับเวลาช่วงที่ช้าที่สุด",
      outcomes: "ได้เส้นฐานของรอบเย็นไว้เปรียบเทียบ",
      blockers: "ยังรอข้อมูลของเดือนที่แล้ว",
      hours: 32
    )
  end

  # The university's seat, and the student's own work. An administrator assigns
  # the supervisor because that is the only way one is granted (ADR-0041
  # decision 2), and the deliverable belongs to the student who uploaded it.
  if placement.faculty_assignments.active.none?
    placement.faculty_assignments.create!(faculty:, assigned_by: admin)
  end

  if placement.deliverables.none?
    deliverable = placement.deliverables.new(title: "สรุปเส้นทางรอบเย็น", author: demo_student)
    deliverable.file.attach(io: StringIO.new("%PDF-1.4 demo deliverable"),
                            filename: "route-analysis.pdf", content_type: "application/pdf")
    deliverable.save!
  end

  puts "Seeded 1 internship — #{demo_student.name} at #{company.name}: " \
       "request #{internship_request.status}, placement #{placement.status}, " \
       "#{placement.progress_reports.count} weekly report, supervisor #{placement.supervisor&.name}, " \
       "#{placement.deliverables.count} deliverable"

  puts "Seeded #{User.count} users — student 2011071730001 at /login; " \
       "instructor wichai, admin utcc-admin, company northstar at /console; password utcc2026 for all"
  puts "Seeded #{TopicCompletion.count} topic completions"
end
