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

ActiveRecord::Schema[8.0].define(version: 2025_02_19_185010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "stock_data", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.decimal "last_price_deal", precision: 10, scale: 2, null: false
    t.decimal "changed_price", precision: 10, scale: 2
    t.decimal "first_price", precision: 10, scale: 2
    t.decimal "max_price", precision: 10, scale: 2
    t.decimal "min_price", precision: 10, scale: 2
    t.decimal "close_price", precision: 10, scale: 2
    t.integer "quantity_selled", default: 0, null: false
    t.datetime "time_update", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_stock_data_on_stock_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "stock_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_name"], name: "index_stocks_on_stock_name", unique: true
  end

  add_foreign_key "stock_data", "stocks"
end
