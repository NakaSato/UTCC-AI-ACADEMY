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

ActiveRecord::Schema[8.1].define(version: 2026_08_12_220000) do
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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

  create_table "business_case_comments", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "business_case_id", null: false
    t.datetime "created_at", null: false
    t.datetime "posted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_business_case_comments_on_author_id"
    t.index ["business_case_id", "id"], name: "index_business_case_comments_on_business_case_id_and_id"
  end

  create_table "business_case_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "business_case_id", null: false
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.datetime "expires_at", null: false
    t.bigint "invitee_id", null: false
    t.bigint "inviter_id", null: false
    t.datetime "revoked_at"
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["business_case_id", "invitee_id"], name: "business_case_invitations_one_open", unique: true, where: "((accepted_at IS NULL) AND (declined_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["business_case_id"], name: "index_business_case_invitations_on_business_case_id"
    t.index ["invitee_id"], name: "index_business_case_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_business_case_invitations_on_inviter_id"
    t.index ["token_digest"], name: "index_business_case_invitations_on_token_digest", unique: true
    t.check_constraint "NOT (accepted_at IS NOT NULL AND declined_at IS NOT NULL)", name: "business_case_invitations_one_decision"
  end

  create_table "business_case_milestones", force: :cascade do |t|
    t.bigint "business_case_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", null: false
    t.string "status", default: "open", null: false
    t.string "title", limit: 160, null: false
    t.datetime "updated_at", null: false
    t.index ["business_case_id", "position"], name: "idx_on_business_case_id_position_628c92fe3a", unique: true
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'completed'::character varying]::text[])", name: "business_case_milestones_status"
  end

  create_table "business_case_participants", force: :cascade do |t|
    t.bigint "assigned_by_id"
    t.bigint "business_case_id", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["business_case_id", "user_id"], name: "business_case_participants_one_active", unique: true, where: "(revoked_at IS NULL)"
    t.index ["business_case_id"], name: "index_business_case_participants_on_business_case_id"
    t.index ["user_id"], name: "index_business_case_participants_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['student'::character varying, 'mentor'::character varying]::text[])", name: "business_case_participants_role"
  end

  create_table "business_case_submissions", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "business_case_id", null: false
    t.bigint "business_case_milestone_id", null: false
    t.datetime "created_at", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["author_id"], name: "index_business_case_submissions_on_author_id"
    t.index ["business_case_id"], name: "index_business_case_submissions_on_business_case_id"
    t.index ["business_case_milestone_id", "author_id", "version"], name: "business_case_submissions_one_version", unique: true
    t.check_constraint "version >= 1", name: "business_case_submissions_version"
  end

  create_table "business_cases", force: :cascade do |t|
    t.text "brief"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "organization_id", null: false
    t.bigint "owner_id", null: false
    t.datetime "published_at"
    t.text "requirements"
    t.string "status", default: "draft", null: false
    t.string "title", limit: 160, null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "status"], name: "index_business_cases_on_organization_id_and_status"
    t.index ["owner_id"], name: "index_business_cases_on_owner_id"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying, 'closed'::character varying]::text[])", name: "business_cases_status"
  end

  create_table "candidate_profile_facts", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.decimal "confidence", precision: 4, scale: 3, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.text "detail", default: "", null: false
    t.string "kind", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "organization", default: "", null: false
    t.integer "position", default: 0, null: false
    t.string "source", default: "self_reported", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "kind", "position"], name: "candidate_profile_facts_order"
    t.check_constraint "confidence >= 0::numeric AND confidence <= 1::numeric", name: "candidate_profile_facts_confidence"
    t.check_constraint "kind::text = ANY (ARRAY['education'::character varying, 'experience'::character varying, 'skill'::character varying, 'certification'::character varying, 'language'::character varying]::text[])", name: "candidate_profile_facts_kind"
    t.check_constraint "source::text = ANY (ARRAY['self_reported'::character varying, 'document_extracted'::character varying, 'human_reviewed'::character varying]::text[])", name: "candidate_profile_facts_source"
  end

  create_table "candidate_profiles", force: :cascade do |t|
    t.boolean "application_data_reuse_consent", default: false, null: false
    t.datetime "consent_given_at"
    t.datetime "created_at", null: false
    t.string "github_url"
    t.string "headline"
    t.string "linkedin_url"
    t.integer "lock_version", default: 0, null: false
    t.string "portfolio_url"
    t.string "preferred_location"
    t.string "salary_currency", limit: 3, default: "THB", null: false
    t.integer "salary_expectation_max"
    t.integer "salary_expectation_min"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "visibility", default: "private", null: false
    t.index ["user_id"], name: "index_candidate_profiles_on_user_id", unique: true
    t.check_constraint "salary_expectation_max IS NULL OR salary_expectation_max >= 0", name: "candidate_profiles_salary_max"
    t.check_constraint "salary_expectation_min IS NULL OR salary_expectation_max IS NULL OR salary_expectation_min <= salary_expectation_max", name: "candidate_profiles_salary_range"
    t.check_constraint "salary_expectation_min IS NULL OR salary_expectation_min >= 0", name: "candidate_profiles_salary_min"
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

  create_table "internship_deliverables", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.bigint "internship_placement_id", null: false
    t.string "title", limit: 160, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_internship_deliverables_on_author_id"
    t.index ["internship_placement_id", "created_at"], name: "idx_on_internship_placement_id_created_at_c22f9fd067"
  end

  create_table "internship_faculty_assignments", force: :cascade do |t|
    t.bigint "assigned_by_id", null: false
    t.datetime "created_at", null: false
    t.bigint "faculty_id", null: false
    t.bigint "internship_placement_id", null: false
    t.datetime "revoked_at"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_internship_faculty_assignments_on_assigned_by_id"
    t.index ["faculty_id", "status"], name: "index_internship_faculty_assignments_on_faculty_id_and_status"
    t.index ["internship_placement_id"], name: "internship_faculty_assignments_one_active", unique: true, where: "((status)::text = 'active'::text)"
    t.check_constraint "status::text <> 'revoked'::text OR revoked_at IS NOT NULL", name: "internship_faculty_assignments_revoked_at"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'revoked'::character varying]::text[])", name: "internship_faculty_assignments_status"
  end

  create_table "internship_placements", force: :cascade do |t|
    t.datetime "activated_at"
    t.bigint "application_id"
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "ends_on"
    t.bigint "internship_request_id"
    t.integer "lock_version", default: 0, null: false
    t.bigint "organization_id", null: false
    t.date "starts_on"
    t.string "status", default: "planned", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_internship_placements_on_application_id", unique: true, where: "(application_id IS NOT NULL)"
    t.index ["internship_request_id"], name: "index_internship_placements_on_internship_request_id", unique: true, where: "(internship_request_id IS NOT NULL)"
    t.index ["organization_id", "status"], name: "index_internship_placements_on_organization_id_and_status"
    t.index ["student_id", "status"], name: "index_internship_placements_on_student_id_and_status"
    t.check_constraint "(internship_request_id IS NULL) <> (application_id IS NULL)", name: "internship_placements_one_origin"
    t.check_constraint "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on", name: "internship_placements_dates"
    t.check_constraint "status::text <> 'cancelled'::text OR cancellation_reason IS NOT NULL AND cancellation_reason <> ''::text", name: "internship_placements_cancellation_reason"
    t.check_constraint "status::text = ANY (ARRAY['planned'::character varying, 'active'::character varying, 'completed'::character varying, 'cancelled'::character varying]::text[])", name: "internship_placements_status"
  end

  create_table "internship_progress_reports", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.bigint "acknowledged_by_id"
    t.text "activities", null: false
    t.text "blockers"
    t.datetime "created_at", null: false
    t.datetime "faculty_acknowledged_at"
    t.bigint "faculty_acknowledged_by_id"
    t.decimal "hours", precision: 5, scale: 1
    t.bigint "internship_placement_id", null: false
    t.text "outcomes"
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.date "week_starting_on", null: false
    t.index ["acknowledged_by_id"], name: "index_internship_progress_reports_on_acknowledged_by_id"
    t.index ["faculty_acknowledged_by_id"], name: "idx_on_faculty_acknowledged_by_id_3bf38c7c61"
    t.index ["internship_placement_id", "week_starting_on"], name: "internship_progress_reports_one_per_week", unique: true
    t.check_constraint "hours IS NULL OR hours >= 0::numeric AND hours <= 168::numeric", name: "internship_progress_reports_hours"
  end

  create_table "internship_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.bigint "decided_by_id"
    t.text "decision_reason"
    t.text "learning_goals", null: false
    t.integer "lock_version", default: 0, null: false
    t.text "motivation", null: false
    t.bigint "organization_id", null: false
    t.datetime "resume_shared_at"
    t.datetime "reviewed_at"
    t.string "status", default: "draft", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.datetime "withdrawn_at"
    t.index ["decided_by_id"], name: "index_internship_requests_on_decided_by_id"
    t.index ["organization_id", "status"], name: "index_internship_requests_on_organization_id_and_status"
    t.index ["organization_id", "student_id"], name: "internship_requests_one_open", unique: true, where: "((decided_at IS NULL) AND (withdrawn_at IS NULL))"
    t.index ["student_id", "status"], name: "index_internship_requests_on_student_id_and_status"
    t.check_constraint "status::text <> 'rejected'::text OR decision_reason IS NOT NULL AND decision_reason <> ''::text", name: "internship_requests_rejection_reason"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'submitted'::character varying, 'under_review'::character varying, 'approved'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[])", name: "internship_requests_status"
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

  create_table "lesson_integrity_settings", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "lock_version", default: 0, null: false
    t.string "topic_key", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "topic_key"], name: "index_lesson_integrity_settings_on_course_id_and_topic_key", unique: true
    t.index ["course_id"], name: "index_lesson_integrity_settings_on_course_id"
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

  create_table "organization_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.datetime "expires_at", null: false
    t.bigint "invitee_id", null: false
    t.bigint "inviter_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "revoked_at"
    t.string "role", default: "recruiter", null: false
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.index ["invitee_id"], name: "index_organization_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_organization_invitations_on_inviter_id"
    t.index ["organization_id", "invitee_id"], name: "organization_invitations_one_open", unique: true, where: "((accepted_at IS NULL) AND (declined_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["organization_id"], name: "index_organization_invitations_on_organization_id"
    t.index ["token_digest"], name: "index_organization_invitations_on_token_digest", unique: true
    t.check_constraint "NOT (accepted_at IS NOT NULL AND declined_at IS NOT NULL)", name: "organization_invitations_one_decision"
    t.check_constraint "role::text = ANY (ARRAY['recruiter'::character varying, 'hiring_manager'::character varying, 'mentor'::character varying, 'company_reviewer'::character varying]::text[])", name: "organization_invitations_role"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "recruiter", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_and_user", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_active_owner", unique: true, where: "(((role)::text = 'owner'::text) AND ((status)::text = 'active'::text))"
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "accepts_internship_requests", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_organizations_on_creator_id"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "prior_knowledges", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "marked_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["course_id"], name: "index_prior_knowledges_on_course_id"
    t.index ["topic_id"], name: "index_prior_knowledges_on_topic_id"
    t.index ["user_id", "course_id", "topic_id"], name: "index_prior_knowledges_on_user_id_and_course_id_and_topic_id", unique: true
    t.index ["user_id", "course_id"], name: "index_prior_knowledges_on_user_id_and_course_id"
    t.index ["user_id"], name: "index_prior_knowledges_on_user_id"
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

  create_table "proposal_requests", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "idea", null: false
    t.text "impact", null: false
    t.text "problem", null: false
    t.string "status", default: "submitted", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status", "created_at"], name: "index_proposal_requests_on_status_and_created_at"
    t.index ["user_id", "created_at"], name: "index_proposal_requests_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_proposal_requests_on_user_id"
    t.check_constraint "category::text = ANY (ARRAY['feature'::character varying, 'curriculum'::character varying, 'community'::character varying, 'platform'::character varying]::text[])", name: "proposal_requests_category"
    t.check_constraint "status::text = ANY (ARRAY['submitted'::character varying, 'in_review'::character varying, 'planned'::character varying, 'declined'::character varying]::text[])", name: "proposal_requests_status"
  end

  create_table "recruitment_candidate_resume_analyses", force: :cascade do |t|
    t.datetime "applied_at"
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "provider", null: false
    t.bigint "requested_by_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.jsonb "source_context", default: {}, null: false
    t.string "source_label", null: false
    t.string "status", default: "pending", null: false
    t.text "uncertainty", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "generated_at"], name: "recruitment_resume_analyses_newest"
    t.index ["candidate_profile_id"], name: "idx_on_candidate_profile_id_03073ab97e"
    t.index ["requested_by_id"], name: "index_recruitment_candidate_resume_analyses_on_requested_by_id"
    t.index ["reviewed_by_id"], name: "index_recruitment_candidate_resume_analyses_on_reviewed_by_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'reviewed'::character varying, 'applied'::character varying, 'rejected'::character varying]::text[])", name: "recruitment_resume_analyses_status"
  end

  create_table "recruitment_candidate_resume_findings", force: :cascade do |t|
    t.bigint "analysis_id", null: false
    t.bigint "applied_fact_id"
    t.decimal "confidence", precision: 4, scale: 3, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.text "detail", default: "", null: false
    t.text "evidence", default: "", null: false
    t.boolean "inferred", default: false, null: false
    t.string "kind", null: false
    t.integer "position", default: 0, null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "source_type", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_id"], name: "index_recruitment_candidate_resume_findings_on_analysis_id"
    t.index ["applied_fact_id"], name: "index_recruitment_candidate_resume_findings_on_applied_fact_id"
    t.index ["reviewed_by_id"], name: "index_recruitment_candidate_resume_findings_on_reviewed_by_id"
    t.check_constraint "confidence >= 0::numeric AND confidence <= 1::numeric", name: "recruitment_resume_findings_confidence"
    t.check_constraint "kind::text = ANY (ARRAY['skill'::character varying, 'tool'::character varying, 'experience'::character varying, 'seniority'::character varying, 'qualification'::character varying, 'ats_signal'::character varying, 'skill_gap'::character varying, 'strength'::character varying, 'uncertainty'::character varying]::text[])", name: "recruitment_resume_findings_kind"
    t.check_constraint "source_type::text = ANY (ARRAY['resume_text'::character varying, 'resume_metadata'::character varying, 'rules_inference'::character varying]::text[])", name: "recruitment_resume_findings_source_type"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'edited'::character varying, 'accepted'::character varying, 'rejected'::character varying]::text[])", name: "recruitment_resume_findings_status"
  end

  create_table "recruitment_internship_applications", force: :cascade do |t|
    t.datetime "applied_at", null: false
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "program_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "statement", default: "", null: false
    t.string "status", default: "pending", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id", "status", "created_at"], name: "recruitment_internship_applications_program_status"
    t.index ["program_id", "student_id"], name: "recruitment_internship_applications_one_per_student", unique: true
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[])", name: "recruitment_internship_applications_status"
  end

  create_table "recruitment_internship_evaluations", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.bigint "evaluator_id", null: false
    t.text "feedback", default: "", null: false
    t.boolean "learning_outcomes_met"
    t.integer "lock_version", default: 0, null: false
    t.text "next_steps", default: "", null: false
    t.integer "rating"
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "recruitment_internship_evaluations_one_per_application", unique: true
    t.check_constraint "rating IS NULL OR rating >= 1 AND rating <= 5", name: "recruitment_internship_evaluations_rating"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'submitted'::character varying]::text[])", name: "recruitment_internship_evaluations_status"
  end

  create_table "recruitment_internship_program_suggestions", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.string "kind", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "model"
    t.bigint "program_id", null: false
    t.string "provider", null: false
    t.bigint "requested_by_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.jsonb "source_context", default: {}, null: false
    t.text "source_label", null: false
    t.string "status", default: "pending", null: false
    t.text "uncertainty", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id", "kind"], name: "recruitment_internship_suggestions_one_actionable", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'edited'::character varying])::text[]))"
    t.check_constraint "kind::text = ANY (ARRAY['description'::character varying, 'learning_roadmap'::character varying, 'mentor_guide'::character varying, 'evaluation_criteria'::character varying, 'final_project'::character varying]::text[])", name: "recruitment_internship_suggestions_kind"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'edited'::character varying, 'accepted'::character varying, 'rejected'::character varying]::text[])", name: "recruitment_internship_suggestions_status"
  end

  create_table "recruitment_internship_programs", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "certificate_policy", default: "", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.string "department", default: "", null: false
    t.text "description", default: "", null: false
    t.integer "duration_weeks", default: 1, null: false
    t.text "equipment_provided", default: "", null: false
    t.text "learning_outcomes", default: "", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "max_students", default: 1, null: false
    t.bigint "mentor_id"
    t.string "name", default: "", null: false
    t.bigint "organization_id", null: false
    t.boolean "paid", default: false, null: false
    t.datetime "published_at"
    t.string "remote_policy", default: "onsite", null: false
    t.text "required_skills", default: "", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.text "working_days", default: "", null: false
    t.index ["organization_id", "status", "updated_at"], name: "recruitment_internship_programs_management"
    t.index ["organization_id"], name: "index_recruitment_internship_programs_on_organization_id"
    t.index ["status", "published_at"], name: "recruitment_internship_programs_publication"
    t.check_constraint "duration_weeks >= 1 AND duration_weeks <= 104", name: "recruitment_internship_programs_duration"
    t.check_constraint "max_students > 0", name: "recruitment_internship_programs_capacity"
    t.check_constraint "remote_policy::text = ANY (ARRAY['onsite'::character varying, 'hybrid'::character varying, 'remote'::character varying]::text[])", name: "recruitment_internship_programs_remote_policy"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'review'::character varying, 'published'::character varying, 'paused'::character varying, 'closed'::character varying, 'archived'::character varying]::text[])", name: "recruitment_internship_programs_status"
  end

  create_table "recruitment_job_application_events", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status"
    t.bigint "job_application_id", null: false
    t.text "note", default: "", null: false
    t.datetime "occurred_at", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["job_application_id", "occurred_at", "id"], name: "recruitment_job_application_events_history"
    t.check_constraint "from_status IS NULL OR (from_status::text = ANY (ARRAY['submitted'::character varying, 'screening'::character varying, 'interview'::character varying, 'offer'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[]))", name: "recruitment_job_application_events_from_status"
    t.check_constraint "to_status::text = ANY (ARRAY['submitted'::character varying, 'screening'::character varying, 'interview'::character varying, 'offer'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[])", name: "recruitment_job_application_events_to_status"
  end

  create_table "recruitment_job_application_messages", force: :cascade do |t|
    t.text "body", default: "", null: false
    t.datetime "created_at", null: false
    t.bigint "job_application_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "sent_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_application_id", "sent_at", "id"], name: "recruitment_job_application_messages_history"
    t.check_constraint "char_length(btrim(body)) > 0 AND char_length(body) <= 4000", name: "recruitment_job_application_messages_body"
  end

  create_table "recruitment_job_applications", force: :cascade do |t|
    t.jsonb "application_snapshot", default: {}, null: false
    t.datetime "applied_at", null: false
    t.bigint "candidate_id", null: false
    t.datetime "created_at", null: false
    t.bigint "job_post_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "statement", default: "", null: false
    t.string "status", default: "submitted", null: false
    t.datetime "updated_at", null: false
    t.datetime "withdrawn_at"
    t.index ["job_post_id", "candidate_id"], name: "recruitment_job_applications_one_per_candidate", unique: true
    t.index ["job_post_id", "status", "created_at"], name: "recruitment_job_applications_pipeline"
    t.check_constraint "status::text = ANY (ARRAY['submitted'::character varying, 'screening'::character varying, 'interview'::character varying, 'offer'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[])", name: "recruitment_job_applications_status"
  end

  create_table "recruitment_job_discovery_dismissals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "job_post_id"], name: "recruitment_discovery_dismissals_one_per_user", unique: true
  end

  create_table "recruitment_job_discovery_preferences", force: :cascade do |t|
    t.boolean "alert_consent", default: false, null: false
    t.datetime "alert_consent_given_at"
    t.string "alert_frequency", default: "weekly", null: false
    t.boolean "alerts_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.string "employment_type", default: "", null: false
    t.datetime "last_alert_sent_at"
    t.string "location", default: "", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "remote_policy", default: "", null: false
    t.string "search_query", default: "", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "recruitment_discovery_preferences_one_per_user", unique: true
    t.check_constraint "NOT alerts_enabled OR alert_consent", name: "recruitment_discovery_preferences_consent"
    t.check_constraint "alert_frequency::text = ANY (ARRAY['daily'::character varying, 'weekly'::character varying]::text[])", name: "recruitment_discovery_preferences_frequency"
  end

  create_table "recruitment_job_post_suggestions", force: :cascade do |t|
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.bigint "job_post_id", null: false
    t.string "kind", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "model"
    t.string "provider", null: false
    t.bigint "requested_by_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.jsonb "source_context", default: {}, null: false
    t.string "source_label", null: false
    t.string "status", default: "pending", null: false
    t.text "uncertainty", null: false
    t.datetime "updated_at", null: false
    t.index ["job_post_id", "kind"], name: "recruitment_job_suggestions_one_actionable", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'edited'::character varying])::text[]))"
    t.index ["job_post_id"], name: "index_recruitment_job_post_suggestions_on_job_post_id"
    t.index ["requested_by_id"], name: "index_recruitment_job_post_suggestions_on_requested_by_id"
    t.index ["reviewed_by_id"], name: "index_recruitment_job_post_suggestions_on_reviewed_by_id"
    t.check_constraint "kind::text = ANY (ARRAY['summary'::character varying, 'description'::character varying, 'requirements'::character varying, 'interview_questions'::character varying, 'inclusive_language'::character varying]::text[])", name: "recruitment_job_suggestions_kind"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'edited'::character varying, 'accepted'::character varying, 'rejected'::character varying]::text[])", name: "recruitment_job_suggestions_status"
  end

  create_table "recruitment_job_posts", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "category", default: "", null: false
    t.datetime "closed_at"
    t.date "closes_on"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.string "currency", limit: 3, default: "THB", null: false
    t.string "department", default: "", null: false
    t.text "description", default: "", null: false
    t.string "employment_type", default: "full_time", null: false
    t.text "hiring_reason", default: "", null: false
    t.string "location", default: "", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "organization_id", null: false
    t.integer "positions_count", default: 1, null: false
    t.datetime "published_at"
    t.string "remote_policy", default: "onsite", null: false
    t.integer "salary_max"
    t.integer "salary_min"
    t.string "seniority", default: "", null: false
    t.string "status", default: "draft", null: false
    t.text "summary", default: "", null: false
    t.string "team", default: "", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_recruitment_job_posts_on_creator_id"
    t.index ["organization_id", "status", "updated_at"], name: "recruitment_job_posts_management"
    t.index ["organization_id"], name: "index_recruitment_job_posts_on_organization_id"
    t.index ["status", "closes_on", "published_at"], name: "recruitment_job_posts_candidate_visibility"
    t.check_constraint "employment_type::text = ANY (ARRAY['full_time'::character varying, 'part_time'::character varying, 'internship'::character varying, 'contract'::character varying, 'freelance'::character varying]::text[])", name: "recruitment_job_posts_employment_type"
    t.check_constraint "positions_count > 0", name: "recruitment_job_posts_positions_count"
    t.check_constraint "remote_policy::text = ANY (ARRAY['onsite'::character varying, 'hybrid'::character varying, 'remote'::character varying]::text[])", name: "recruitment_job_posts_remote_policy"
    t.check_constraint "salary_max IS NULL OR salary_max >= 0", name: "recruitment_job_posts_salary_max"
    t.check_constraint "salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max", name: "recruitment_job_posts_salary_range"
    t.check_constraint "salary_min IS NULL OR salary_min >= 0", name: "recruitment_job_posts_salary_min"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'review'::character varying, 'published'::character varying, 'paused'::character varying, 'closed'::character varying, 'archived'::character varying]::text[])", name: "recruitment_job_posts_status"
  end

  create_table "recruitment_saved_jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "recruitment_saved_jobs_recent"
    t.index ["user_id", "job_post_id"], name: "recruitment_saved_jobs_one_per_user", unique: true
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
    t.string "student_id"
    t.integer "study_year"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["student_id"], name: "index_users_on_student_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
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
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "approval_decisions", "approval_requests"
  add_foreign_key "approval_decisions", "users", column: "actor_id"
  add_foreign_key "approval_requests", "courses"
  add_foreign_key "approval_requests", "users", column: "requester_id"
  add_foreign_key "audit_events", "users"
  add_foreign_key "business_case_comments", "business_cases"
  add_foreign_key "business_case_comments", "users", column: "author_id"
  add_foreign_key "business_case_invitations", "business_cases"
  add_foreign_key "business_case_invitations", "users", column: "invitee_id"
  add_foreign_key "business_case_invitations", "users", column: "inviter_id"
  add_foreign_key "business_case_milestones", "business_cases"
  add_foreign_key "business_case_participants", "business_cases"
  add_foreign_key "business_case_participants", "users"
  add_foreign_key "business_case_participants", "users", column: "assigned_by_id"
  add_foreign_key "business_case_submissions", "business_case_milestones"
  add_foreign_key "business_case_submissions", "business_cases"
  add_foreign_key "business_case_submissions", "users", column: "author_id"
  add_foreign_key "business_cases", "organizations"
  add_foreign_key "business_cases", "users", column: "owner_id"
  add_foreign_key "candidate_profile_facts", "candidate_profiles"
  add_foreign_key "candidate_profiles", "users"
  add_foreign_key "course_modules", "courses"
  add_foreign_key "enrollments", "sections"
  add_foreign_key "enrollments", "users"
  add_foreign_key "internship_deliverables", "internship_placements"
  add_foreign_key "internship_deliverables", "users", column: "author_id"
  add_foreign_key "internship_faculty_assignments", "internship_placements"
  add_foreign_key "internship_faculty_assignments", "users", column: "assigned_by_id"
  add_foreign_key "internship_faculty_assignments", "users", column: "faculty_id"
  add_foreign_key "internship_placements", "internship_requests"
  add_foreign_key "internship_placements", "organizations"
  add_foreign_key "internship_placements", "recruitment_internship_applications", column: "application_id"
  add_foreign_key "internship_placements", "users", column: "student_id"
  add_foreign_key "internship_progress_reports", "internship_placements"
  add_foreign_key "internship_progress_reports", "users", column: "acknowledged_by_id"
  add_foreign_key "internship_progress_reports", "users", column: "faculty_acknowledged_by_id"
  add_foreign_key "internship_requests", "organizations"
  add_foreign_key "internship_requests", "users", column: "decided_by_id"
  add_foreign_key "internship_requests", "users", column: "student_id"
  add_foreign_key "lesson_integrity_settings", "courses"
  add_foreign_key "notifications", "users"
  add_foreign_key "organization_invitations", "organizations"
  add_foreign_key "organization_invitations", "users", column: "invitee_id"
  add_foreign_key "organization_invitations", "users", column: "inviter_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "organizations", "users", column: "creator_id"
  add_foreign_key "prior_knowledges", "courses"
  add_foreign_key "prior_knowledges", "topics"
  add_foreign_key "prior_knowledges", "users"
  add_foreign_key "proctor_events", "courses"
  add_foreign_key "proctor_events", "topics"
  add_foreign_key "proctor_events", "users"
  add_foreign_key "proposal_requests", "users"
  add_foreign_key "recruitment_candidate_resume_analyses", "candidate_profiles"
  add_foreign_key "recruitment_candidate_resume_analyses", "users", column: "requested_by_id"
  add_foreign_key "recruitment_candidate_resume_analyses", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_candidate_resume_findings", "candidate_profile_facts", column: "applied_fact_id"
  add_foreign_key "recruitment_candidate_resume_findings", "recruitment_candidate_resume_analyses", column: "analysis_id"
  add_foreign_key "recruitment_candidate_resume_findings", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_internship_applications", "recruitment_internship_programs", column: "program_id"
  add_foreign_key "recruitment_internship_applications", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_internship_applications", "users", column: "student_id"
  add_foreign_key "recruitment_internship_evaluations", "recruitment_internship_applications", column: "application_id"
  add_foreign_key "recruitment_internship_evaluations", "users", column: "evaluator_id"
  add_foreign_key "recruitment_internship_program_suggestions", "recruitment_internship_programs", column: "program_id"
  add_foreign_key "recruitment_internship_program_suggestions", "users", column: "requested_by_id"
  add_foreign_key "recruitment_internship_program_suggestions", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_internship_programs", "organizations"
  add_foreign_key "recruitment_internship_programs", "users", column: "creator_id"
  add_foreign_key "recruitment_internship_programs", "users", column: "mentor_id"
  add_foreign_key "recruitment_job_application_events", "recruitment_job_applications", column: "job_application_id"
  add_foreign_key "recruitment_job_application_events", "users", column: "actor_id"
  add_foreign_key "recruitment_job_application_messages", "recruitment_job_applications", column: "job_application_id"
  add_foreign_key "recruitment_job_application_messages", "users", column: "sender_id"
  add_foreign_key "recruitment_job_applications", "recruitment_job_posts", column: "job_post_id"
  add_foreign_key "recruitment_job_applications", "users", column: "candidate_id"
  add_foreign_key "recruitment_job_applications", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_job_discovery_dismissals", "recruitment_job_posts", column: "job_post_id"
  add_foreign_key "recruitment_job_discovery_dismissals", "users"
  add_foreign_key "recruitment_job_discovery_preferences", "users"
  add_foreign_key "recruitment_job_post_suggestions", "recruitment_job_posts", column: "job_post_id"
  add_foreign_key "recruitment_job_post_suggestions", "users", column: "requested_by_id"
  add_foreign_key "recruitment_job_post_suggestions", "users", column: "reviewed_by_id"
  add_foreign_key "recruitment_job_posts", "organizations"
  add_foreign_key "recruitment_job_posts", "users", column: "creator_id"
  add_foreign_key "recruitment_saved_jobs", "recruitment_job_posts", column: "job_post_id"
  add_foreign_key "recruitment_saved_jobs", "users"
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
