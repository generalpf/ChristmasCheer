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

ActiveRecord::Schema[8.1].define(version: 2026_05_16_225933) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "affiliates", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "city_towns", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "courtesy_titles", force: :cascade do |t|
    t.string "title", null: false
  end

  create_table "donors", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.bigint "affiliate_id", null: false
    t.bigint "category_id", null: false
    t.bigint "city_town_id"
    t.string "company"
    t.bigint "courtesy_title_id", null: false
    t.datetime "created_at", null: false
    t.string "email1"
    t.string "email2"
    t.string "first_name"
    t.string "job_title"
    t.string "last_name"
    t.text "notes"
    t.string "phone"
    t.string "postal_code"
    t.string "province"
    t.string "spouse"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["affiliate_id"], name: "index_donors_on_affiliate_id"
    t.index ["category_id"], name: "index_donors_on_category_id"
    t.index ["city_town_id"], name: "index_donors_on_city_town_id"
    t.index ["company"], name: "index_donors_on_company"
    t.index ["courtesy_title_id"], name: "index_donors_on_courtesy_title_id"
    t.index ["last_name"], name: "index_donors_on_last_name"
  end

  create_table "payments", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "publications", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "donors", "affiliates"
  add_foreign_key "donors", "categories"
  add_foreign_key "donors", "city_towns"
  add_foreign_key "donors", "courtesy_titles"
  add_foreign_key "sessions", "users"
end
