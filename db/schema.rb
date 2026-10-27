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

ActiveRecord::Schema[8.1].define(version: 2026_10_28_010100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "routine_id", null: false
    t.integer "number", null: false
    t.integer "section", default: 1, null: false
    t.string "name_zh", null: false
    t.string "name_pinyin", null: false
    t.string "name_en", null: false
    t.string "name_id", null: false
    t.float "start_sec", default: 0.0, null: false
    t.float "end_sec", default: 0.0, null: false
    t.float "end_x"
    t.float "end_y"
    t.string "facing_en"
    t.string "facing_id"
    t.jsonb "steps", default: {}, null: false
    t.jsonb "key_points", default: {}, null: false
    t.jsonb "mistakes", default: {}, null: false
    t.jsonb "figures", default: [], null: false
    t.string "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["routine_id", "number"], name: "index_movements_on_routine_id_and_number", unique: true
    t.index ["routine_id"], name: "index_movements_on_routine_id"
  end

  create_table "routines", force: :cascade do |t|
    t.string "slug", null: false
    t.string "style", null: false
    t.string "name_zh", null: false
    t.string "name_pinyin", null: false
    t.string "name_en", null: false
    t.string "name_id", null: false
    t.string "card_zh"
    t.string "status", default: "awaiting", null: false
    t.integer "position", default: 0, null: false
    t.integer "reference_page"
    t.string "reference_figure"
    t.float "start_x"
    t.float "start_y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_routines_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "signups_open", default: true, null: false
    t.boolean "verification_required", default: true, null: false
    t.text "notice_en"
    t.text "notice_id"
    t.string "site_name", default: "OpenWushu", null: false
    t.string "contact_email"
    t.text "footer_en"
    t.text "footer_id"
    t.string "source_url", default: "https://github.com/cloudsbird/OpenWushu", null: false
    t.string "mail_from"
    t.string "smtp_address"
    t.integer "smtp_port"
    t.string "smtp_username"
    t.text "smtp_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "display_name", null: false
    t.string "locale", default: "en", null: false
    t.string "club"
    t.datetime "verified_at"
    t.datetime "guidelines_accepted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
    t.datetime "suspended_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "movements", "routines"
  add_foreign_key "sessions", "users"
end
