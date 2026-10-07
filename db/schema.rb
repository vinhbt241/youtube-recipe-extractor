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

ActiveRecord::Schema[8.1].define(version: 2026_10_07_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "recipes", force: :cascade do |t|
    t.string "video_id", null: false
    t.string "url", null: false
    t.string "title"
    t.text "description"
    t.jsonb "ingredients", default: [], null: false
    t.jsonb "instructions", default: [], null: false
    t.integer "prep_time_minutes"
    t.integer "cook_time_minutes"
    t.integer "total_time_minutes"
    t.string "servings"
    t.string "status", default: "pending", null: false
    t.string "error_code"
    t.string "error_message"
    t.text "raw_transcript"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["video_id"], name: "index_recipes_on_video_id", unique: true
  end
end
