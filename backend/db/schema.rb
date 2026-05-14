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

ActiveRecord::Schema[7.1].define(version: 2026_05_16_120003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "notes", force: :cascade do |t|
    t.bigint "offer_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id"], name: "index_notes_on_offer_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string "title", null: false
    t.string "company", null: false
    t.string "location"
    t.string "modality"
    t.string "stack", default: [], array: true
    t.string "url"
    t.string "status", default: "new", null: false
    t.integer "match_score"
    t.string "salary_range"
    t.string "company_size"
    t.date "posted_date"
    t.date "found_date", null: false
    t.date "applied_date"
    t.text "description"
    t.boolean "archived", default: false, null: false
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "score_source", default: "auto", null: false
    t.index ["found_date"], name: "index_offers_on_found_date"
    t.index ["match_score"], name: "index_offers_on_match_score"
    t.index ["source_id"], name: "index_offers_on_source_id"
    t.index ["stack"], name: "index_offers_on_stack", using: :gin
    t.index ["status"], name: "index_offers_on_status"
    t.index ["url"], name: "index_offers_on_url", unique: true, where: "(url IS NOT NULL)"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.string "city"
    t.string "country"
    t.string "email"
    t.string "phone"
    t.string "github"
    t.string "linkedin"
    t.string "start_date"
    t.string "primary_keywords", default: [], null: false, array: true
    t.string "secondary_keywords", default: [], null: false, array: true
    t.string "experimental_keywords", default: [], null: false, array: true
    t.string "positive_title_keywords", default: ["junior", "jr", "entry", "graduate", "trainee", "intern", "internship"], null: false, array: true
    t.string "negative_title_keywords", default: ["mid-level", "5+ years", "7+ years", "8+ years", "10+ years"], null: false, array: true
    t.string "location_bonus_keywords", default: ["remote", "remoto", "hybrid", "hibrido"], null: false, array: true
    t.string "linkedin_keywords", default: ["developer"], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scraper_runs", force: :cascade do |t|
    t.string "source_name", null: false
    t.string "status", default: "pending", null: false
    t.integer "offers_found", default: 0, null: false
    t.integer "offers_created", default: 0, null: false
    t.integer "offers_skipped", default: 0, null: false
    t.jsonb "params", default: {}, null: false
    t.text "error_message"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "search_batch_id"
    t.index ["created_at"], name: "index_scraper_runs_on_created_at"
    t.index ["search_batch_id"], name: "index_scraper_runs_on_search_batch_id"
    t.index ["source_name"], name: "index_scraper_runs_on_source_name"
    t.index ["status"], name: "index_scraper_runs_on_status"
  end

  create_table "search_batches", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.string "sources_requested", default: [], null: false, array: true
    t.integer "offers_found", default: 0, null: false
    t.integer "offers_created", default: 0, null: false
    t.integer "offers_skipped", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_batches_on_created_at"
    t.index ["status"], name: "index_search_batches_on_status"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#4a90b8"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sources_on_name", unique: true
  end

  create_table "status_changes", force: :cascade do |t|
    t.bigint "offer_id", null: false
    t.string "from_status"
    t.string "to_status", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id", "created_at"], name: "index_status_changes_on_offer_id_and_created_at"
    t.index ["offer_id"], name: "index_status_changes_on_offer_id"
  end

  add_foreign_key "notes", "offers"
  add_foreign_key "offers", "sources"
  add_foreign_key "scraper_runs", "search_batches", on_delete: :nullify
  add_foreign_key "status_changes", "offers"
end
