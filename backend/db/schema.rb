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

ActiveRecord::Schema[7.1].define(version: 2026_05_13_120004) do
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
    t.index ["found_date"], name: "index_offers_on_found_date"
    t.index ["match_score"], name: "index_offers_on_match_score"
    t.index ["source_id"], name: "index_offers_on_source_id"
    t.index ["stack"], name: "index_offers_on_stack", using: :gin
    t.index ["status"], name: "index_offers_on_status"
    t.index ["url"], name: "index_offers_on_url", unique: true, where: "(url IS NOT NULL)"
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
  add_foreign_key "status_changes", "offers"
end
