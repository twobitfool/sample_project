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

ActiveRecord::Schema[8.1].define(version: 2026_01_04_230808) do
  create_table "devices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_devices_on_uid", unique: true
  end

  create_table "readings", force: :cascade do |t|
    t.integer "count", null: false
    t.datetime "created_at", null: false
    t.integer "device_id", null: false
    t.datetime "timestamp", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "timestamp"], name: "index_readings_on_device_id_and_timestamp", unique: true
    t.index ["device_id"], name: "index_readings_on_device_id"
  end

  add_foreign_key "readings", "devices"
end
