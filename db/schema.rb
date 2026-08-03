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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_040000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "academic_post_invitations", force: :cascade do |t|
    t.bigint "academic_post_id", null: false
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "invitee_id", null: false
    t.bigint "inviter_id", null: false
    t.string "permission", default: "viewer", null: false
    t.datetime "revoked_at"
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["academic_post_id", "invitee_id"], name: "academic_post_invitations_one_pending", unique: true, where: "((accepted_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["academic_post_id"], name: "index_academic_post_invitations_on_academic_post_id"
    t.index ["invitee_id", "accepted_at", "revoked_at"], name: "idx_on_invitee_id_accepted_at_revoked_at_5cc0987b0f"
    t.index ["invitee_id"], name: "index_academic_post_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_academic_post_invitations_on_inviter_id"
    t.index ["token_digest"], name: "index_academic_post_invitations_on_token_digest", unique: true
    t.check_constraint "inviter_id <> invitee_id", name: "academic_post_invitations_not_self"
    t.check_constraint "permission::text = ANY (ARRAY['viewer'::character varying, 'editor'::character varying]::text[])", name: "academic_post_invitations_permission"
  end

  create_table "academic_post_memberships", force: :cascade do |t|
    t.bigint "academic_post_id", null: false
    t.datetime "created_at", null: false
    t.string "permission", default: "viewer", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["academic_post_id", "user_id"], name: "idx_on_academic_post_id_user_id_a58ffa8cad", unique: true
    t.index ["academic_post_id"], name: "index_academic_post_memberships_on_academic_post_id"
    t.index ["user_id"], name: "index_academic_post_memberships_on_user_id"
    t.check_constraint "permission::text = ANY (ARRAY['viewer'::character varying, 'editor'::character varying]::text[])", name: "academic_post_memberships_permission"
  end

  create_table "academic_post_revisions", force: :cascade do |t|
    t.bigint "academic_post_id", null: false
    t.bigint "author_id", null: false
    t.text "body", default: "", null: false
    t.datetime "created_at", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["academic_post_id", "version"], name: "index_academic_post_revisions_on_academic_post_id_and_version", unique: true
    t.index ["academic_post_id"], name: "index_academic_post_revisions_on_academic_post_id"
    t.index ["author_id"], name: "index_academic_post_revisions_on_author_id"
  end

  create_table "academic_posts", force: :cascade do |t|
    t.text "body", default: "", null: false
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "owner_id", null: false
    t.string "status", default: "draft", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "status"], name: "index_academic_posts_on_owner_id_and_status"
    t.index ["owner_id"], name: "index_academic_posts_on_owner_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "approval_decisions", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "approval_request_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.string "outcome", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_approval_decisions_on_actor_id"
    t.index ["approval_request_id", "created_at"], name: "index_approval_decisions_on_request_and_time"
    t.index ["approval_request_id"], name: "index_approval_decisions_on_approval_request_id"
  end

  create_table "approval_requests", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.string "from_state", null: false
    t.string "kind", null: false
    t.text "note"
    t.bigint "requester_id", null: false
    t.string "status", default: "pending", null: false
    t.string "to_state", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "from_state", "to_state", "status"], name: "index_approval_requests_on_course_transition"
    t.index ["course_id"], name: "index_approval_requests_on_course_id"
    t.index ["requester_id"], name: "index_approval_requests_on_requester_id"
    t.index ["status"], name: "index_approval_requests_on_status"
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.json "params", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["user_id", "created_at"], name: "index_audit_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "course_modules", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.integer "units", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "number"], name: "index_course_modules_on_course_id_and_number", unique: true
    t.index ["course_id"], name: "index_course_modules_on_course_id"
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
    t.string "lifecycle_state", default: "draft", null: false
    t.integer "position", null: false
    t.integer "projects", null: false
    t.string "rating", null: false
    t.json "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_courses_on_code", unique: true
    t.index ["lifecycle_state"], name: "index_courses_on_lifecycle_state"
    t.index ["position"], name: "index_courses_on_position", unique: true
    t.check_constraint "lifecycle_state::text = ANY (ARRAY['draft'::character varying, 'published'::character varying, 'archived'::character varying]::text[])", name: "courses_lifecycle_state"
  end

  create_table "enrollments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "section_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["section_id", "user_id"], name: "index_enrollments_on_section_id_and_user_id", unique: true
    t.index ["section_id"], name: "index_enrollments_on_section_id"
    t.index ["user_id", "section_id"], name: "index_enrollments_on_user_id_and_section_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "feature_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", null: false
    t.string "key", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "scope", default: "global", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "scope"], name: "index_feature_settings_on_key_and_scope", unique: true
  end

  create_table "landing_cards", force: :cascade do |t|
    t.string "collection", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "level"
    t.integer "position", null: false
    t.date "starts_on"
    t.datetime "updated_at", null: false
    t.integer "weeks"
    t.index ["collection", "key"], name: "index_landing_cards_on_collection_and_key", unique: true
    t.index ["collection", "position"], name: "index_landing_cards_on_collection_and_position"
  end

  create_table "landing_texts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "locale", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["key", "locale"], name: "index_landing_texts_on_key_and_locale", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.json "params", default: {}, null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "proctor_events", force: :cascade do |t|
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "reviewed_at"
    t.integer "topic_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["course_id"], name: "index_proctor_events_on_course_id"
    t.index ["topic_id"], name: "index_proctor_events_on_topic_id"
    t.index ["user_id", "occurred_at"], name: "index_proctor_events_on_user_id_and_occurred_at"
    t.index ["user_id", "reviewed_at"], name: "index_proctor_events_on_user_id_and_reviewed_at"
    t.index ["user_id"], name: "index_proctor_events_on_user_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "code", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "instructor_id"
    t.string "term", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "term", "code"], name: "index_sections_on_course_id_and_term_and_code", unique: true
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["instructor_id"], name: "index_sections_on_instructor_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "submissions", force: :cascade do |t|
    t.text "answer", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.boolean "passed", default: false, null: false
    t.integer "score"
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

  add_foreign_key "academic_post_invitations", "academic_posts"
  add_foreign_key "academic_post_invitations", "users", column: "invitee_id"
  add_foreign_key "academic_post_invitations", "users", column: "inviter_id"
  add_foreign_key "academic_post_memberships", "academic_posts"
  add_foreign_key "academic_post_memberships", "users"
  add_foreign_key "academic_post_revisions", "academic_posts"
  add_foreign_key "academic_post_revisions", "users", column: "author_id"
  add_foreign_key "academic_posts", "users", column: "owner_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "approval_decisions", "approval_requests"
  add_foreign_key "approval_decisions", "users", column: "actor_id"
  add_foreign_key "approval_requests", "courses"
  add_foreign_key "approval_requests", "users", column: "requester_id"
  add_foreign_key "audit_events", "users"
  add_foreign_key "course_modules", "courses"
  add_foreign_key "enrollments", "sections"
  add_foreign_key "enrollments", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "proctor_events", "courses"
  add_foreign_key "proctor_events", "topics"
  add_foreign_key "proctor_events", "users"
  add_foreign_key "sections", "courses"
  add_foreign_key "sections", "users", column: "instructor_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "submissions", "courses"
  add_foreign_key "submissions", "topics"
  add_foreign_key "submissions", "users"
  add_foreign_key "topic_completions", "courses"
  add_foreign_key "topic_completions", "topics"
  add_foreign_key "topic_completions", "users"
  add_foreign_key "topics", "course_modules"
end
