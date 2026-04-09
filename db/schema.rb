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

ActiveRecord::Schema[8.1].define(version: 2026_04_09_001506) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
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

  create_table "admin_login_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_admin_login_histories_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["task_id"], name: "index_comments_on_task_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.string "feature_category", null: false
    t.json "metadata", default: {}
    t.datetime "occurred_at", null: false
    t.integer "project_id"
    t.integer "task_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_name"], name: "index_events_on_event_name"
    t.index ["feature_category"], name: "index_events_on_feature_category"
    t.index ["occurred_at"], name: "index_events_on_occurred_at"
    t.index ["project_id"], name: "index_events_on_project_id"
    t.index ["task_id"], name: "index_events_on_task_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "llm_models", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.boolean "default_model", default: false
    t.string "display_name"
    t.bigint "llm_provider_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["default_model"], name: "index_llm_models_on_default_model"
    t.index ["llm_provider_id", "name"], name: "index_llm_models_on_llm_provider_id_and_name", unique: true
    t.index ["llm_provider_id"], name: "index_llm_models_on_llm_provider_id"
  end

  create_table "llm_providers", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "api_key_encrypted"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "organization_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_llm_providers_on_name", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "action"], name: "index_permissions_on_resource_type_and_action", unique: true
  end

  create_table "project_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "dedicated", default: false, null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_projects_on_owner_id"
  end

  create_table "prompt_sets", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_prompt_sets_on_name", unique: true
  end

  create_table "prompts", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "prompt_set_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["prompt_set_id", "position"], name: "index_prompts_on_prompt_set_id_and_position", unique: true
    t.index ["prompt_set_id"], name: "index_prompts_on_prompt_set_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.boolean "system_role", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
    t.index ["system_role"], name: "index_roles_on_system_role"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "suggested_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.string "name", null: false
    t.bigint "suggestion_response_id", null: false
    t.datetime "updated_at", null: false
    t.index ["suggestion_response_id"], name: "index_suggested_tasks_on_suggestion_response_id"
  end

  create_table "suggestion_config_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "llm_model_id", null: false
    t.integer "prompt_set_id", null: false
    t.integer "suggestion_config_id", null: false
    t.datetime "updated_at", null: false
    t.integer "weight", null: false
    t.index ["llm_model_id"], name: "index_suggestion_config_entries_on_llm_model_id"
    t.index ["prompt_set_id"], name: "index_suggestion_config_entries_on_prompt_set_id"
    t.index ["suggestion_config_id", "llm_model_id", "prompt_set_id"], name: "idx_suggestion_config_entries_unique_combo", unique: true
    t.index ["suggestion_config_id"], name: "index_suggestion_config_entries_on_suggestion_config_id"
  end

  create_table "suggestion_configs", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_suggestion_configs_unique_active", unique: true, where: "active = 1"
  end

  create_table "suggestion_outcomes", force: :cascade do |t|
    t.decimal "acceptance_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.boolean "high_acceptance", default: false, null: false
    t.integer "suggestion_response_id", null: false
    t.integer "total_adopted", default: 0, null: false
    t.integer "total_suggested", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["suggestion_response_id"], name: "index_suggestion_outcomes_on_suggestion_response_id", unique: true
  end

  create_table "suggestion_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "llm_model_id"
    t.text "raw_request"
    t.integer "suggestion_config_entry_id"
    t.integer "suggestion_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_model_id"], name: "index_suggestion_requests_on_llm_model_id"
    t.index ["suggestion_config_entry_id"], name: "index_suggestion_requests_on_suggestion_config_entry_id"
    t.index ["suggestion_session_id"], name: "index_suggestion_requests_on_suggestion_session_id"
  end

  create_table "suggestion_responses", force: :cascade do |t|
    t.integer "completion_tokens", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "prompt_tokens", default: 0, null: false
    t.text "raw_response"
    t.bigint "suggestion_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["suggestion_request_id"], name: "index_suggestion_responses_on_suggestion_request_id"
  end

  create_table "suggestion_sessions", force: :cascade do |t|
    t.text "context"
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "goal", null: false
    t.integer "project_id", null: false
    t.integer "requested_by_id", null: false
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_suggestion_sessions_on_project_id"
    t.index ["requested_by_id"], name: "index_suggestion_sessions_on_requested_by_id"
  end

  create_table "task_series", force: :cascade do |t|
    t.integer "assignee_id"
    t.string "by_weekday"
    t.integer "count"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.integer "end_mode", default: 0, null: false
    t.integer "frequency", null: false
    t.integer "interval", default: 1, null: false
    t.string "name", limit: 100, null: false
    t.integer "occurrences_generated", default: 0, null: false
    t.integer "project_id", null: false
    t.string "rrule", null: false
    t.datetime "stopped_at"
    t.date "until_date"
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_task_series_on_assignee_id"
    t.index ["created_by_id"], name: "index_task_series_on_created_by_id"
    t.index ["project_id"], name: "index_task_series_on_project_id"
    t.index ["stopped_at"], name: "index_task_series_on_stopped_at"
  end

  create_table "task_series_subtasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0, null: false
    t.integer "task_series_id", null: false
    t.datetime "updated_at", null: false
    t.index ["task_series_id"], name: "index_task_series_subtasks_on_task_series_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assignee_id"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "due_date", null: false
    t.string "name", null: false
    t.integer "parent_id"
    t.bigint "project_id", null: false
    t.integer "task_series_id"
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["task_series_id"], name: "index_tasks_on_pending_task_series_id", unique: true, where: "completed = FALSE"
    t.index ["task_series_id"], name: "index_tasks_on_task_series_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "locale", default: "ja", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.string "time_zone", default: "UTC", null: false
    t.boolean "totp_enabled", default: false, null: false
    t.string "totp_secret", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_login_histories", "users"
  add_foreign_key "comments", "tasks"
  add_foreign_key "comments", "users"
  add_foreign_key "events", "projects"
  add_foreign_key "events", "tasks"
  add_foreign_key "events", "users"
  add_foreign_key "llm_models", "llm_providers"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "projects", "users", column: "owner_id"
  add_foreign_key "prompts", "prompt_sets"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "suggested_tasks", "suggestion_responses"
  add_foreign_key "suggestion_config_entries", "llm_models"
  add_foreign_key "suggestion_config_entries", "prompt_sets"
  add_foreign_key "suggestion_config_entries", "suggestion_configs"
  add_foreign_key "suggestion_outcomes", "suggestion_responses"
  add_foreign_key "suggestion_requests", "llm_models"
  add_foreign_key "suggestion_requests", "suggestion_config_entries"
  add_foreign_key "suggestion_requests", "suggestion_sessions"
  add_foreign_key "suggestion_responses", "suggestion_requests"
  add_foreign_key "suggestion_sessions", "projects"
  add_foreign_key "suggestion_sessions", "users", column: "requested_by_id"
  add_foreign_key "task_series", "projects"
  add_foreign_key "task_series", "users", column: "assignee_id"
  add_foreign_key "task_series", "users", column: "created_by_id"
  add_foreign_key "task_series_subtasks", "task_series", on_delete: :cascade
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "task_series"
  add_foreign_key "tasks", "tasks", column: "parent_id", on_delete: :cascade
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "tasks", "users", column: "created_by_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
