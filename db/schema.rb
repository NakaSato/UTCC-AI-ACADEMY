# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_26_093003) do
  create_table "course_modules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.integer "units", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_course_modules_on_number", unique: true
  end

  create_table "courses", force: :cascade do |t|
    t.boolean "certificate", default: false, null: false
    t.string "code", null: false
    t.boolean "core", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "credits", null: false
    t.integer "hours", null: false
    t.string "learners", null: false
    t.string "level", null: false
    t.integer "position", null: false
    t.integer "projects", null: false
    t.string "rating", null: false
    t.json "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_courses_on_code", unique: true
    t.index ["position"], name: "index_courses_on_position", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.text "answer", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.boolean "passed", default: false, null: false
    t.integer "topic_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["course_id"], name: "index_submissions_on_course_id"
    t.index ["topic_id", "kind", "passed"], name: "index_submissions_on_topic_id_and_kind_and_passed"
    t.index ["topic_id"], name: "index_submissions_on_topic_id"
    t.index ["user_id", "topic_id", "kind"], name: "index_submissions_on_user_id_and_topic_id_and_kind"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "topic_completions", force: :cascade do |t|
    t.datetime "applied_at"
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "learned_at", null: false
    t.integer "topic_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["course_id"], name: "index_topic_completions_on_course_id"
    t.index ["topic_id"], name: "index_topic_completions_on_topic_id"
    t.index ["user_id", "course_id", "topic_id"], name: "index_topic_completions_on_user_id_and_course_id_and_topic_id", unique: true
    t.index ["user_id", "learned_at"], name: "index_topic_completions_on_user_id_and_learned_at"
    t.index ["user_id"], name: "index_topic_completions_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.integer "course_module_id", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "kind", null: false
    t.integer "minutes", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["course_module_id", "position"], name: "index_topics_on_course_module_id_and_position", unique: true
    t.index ["course_module_id"], name: "index_topics_on_course_module_id"
    t.index ["key"], name: "index_topics_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "faculty"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.string "student_id", null: false
    t.integer "study_year"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["student_id"], name: "index_users_on_student_id", unique: true
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "submissions", "courses"
  add_foreign_key "submissions", "topics"
  add_foreign_key "submissions", "users"
  add_foreign_key "topic_completions", "courses"
  add_foreign_key "topic_completions", "topics"
  add_foreign_key "topic_completions", "users"
  add_foreign_key "topics", "course_modules"
end
