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

ActiveRecord::Schema[8.1].define(version: 2025_11_30_090501) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "golf_rounds", force: :cascade do |t|
    t.string "course_name", null: false
    t.decimal "course_rating", precision: 4, scale: 1, null: false
    t.datetime "created_at", null: false
    t.date "played_at"
    t.integer "score", null: false
    t.integer "slope_rating", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_golf_rounds_on_user_id"
  end

  create_table "handicap_calculation_rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "golf_round_id", null: false
    t.bigint "handicap_calculation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["golf_round_id"], name: "index_handicap_calculation_rounds_on_golf_round_id"
    t.index ["handicap_calculation_id"], name: "index_handicap_calculation_rounds_on_handicap_calculation_id"
  end

  create_table "handicap_calculations", force: :cascade do |t|
    t.text "ai_context"
    t.decimal "calculated_handicap", precision: 4, scale: 1, null: false
    t.string "calculation_method", default: "predicted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_handicap_calculations_on_user_id"
  end

  create_table "training_plans", force: :cascade do |t|
    t.text "complex_guide"
    t.datetime "created_at", null: false
    t.decimal "current_handicap", precision: 4, scale: 1, null: false
    t.bigint "handicap_calculation_id"
    t.text "medium_guide"
    t.text "simple_guide"
    t.decimal "target_handicap", precision: 4, scale: 1, null: false
    t.integer "timeline_months", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["handicap_calculation_id"], name: "index_training_plans_on_handicap_calculation_id"
    t.index ["user_id"], name: "index_training_plans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "has_official_handicap", default: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "golf_rounds", "users"
  add_foreign_key "handicap_calculation_rounds", "golf_rounds"
  add_foreign_key "handicap_calculation_rounds", "handicap_calculations"
  add_foreign_key "handicap_calculations", "users"
  add_foreign_key "training_plans", "handicap_calculations"
  add_foreign_key "training_plans", "users"
end
