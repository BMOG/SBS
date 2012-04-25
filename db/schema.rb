# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120425084115) do

  create_table "contexts", :force => true do |t|
    t.string   "remember_token"
    t.integer  "user_id"
    t.integer  "game_id"
    t.integer  "scenario_id"
    t.integer  "current_turn"
    t.integer  "current_unit"
    t.integer  "current_hex"
    t.string   "action"
    t.float    "scale"
    t.integer  "windows_width"
    t.integer  "windows_height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contexts", ["remember_token"], :name => "index_contexts_on_remember_token", :unique => true

  create_table "grids", :force => true do |t|
    t.integer  "scenario_id"
    t.integer  "picture_width"
    t.integer  "picture_height"
    t.integer  "maxcol"
    t.integer  "maxlin"
    t.integer  "hex_side_length"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "grids", ["scenario_id"], :name => "index_grids_on_scenario_id"

  create_table "parameters", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scenarios", :force => true do |t|
    t.string   "name"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token", :unique => true

end
