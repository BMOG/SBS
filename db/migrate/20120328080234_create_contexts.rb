class CreateContexts < ActiveRecord::Migration
  def change
    create_table :contexts do |t|
      t.string  :remember_token
      t.integer :user_id
      t.integer :game_id
      t.integer :scenario_id
      t.integer :current_turn
      t.integer :current_unit
      t.integer :current_hex
      t.string  :action
      t.float   :scale
      t.integer :windows_width
      t.integer :windows_height
   
      t.timestamps
    end
    
    add_index :contexts, :remember_token, unique: true
  end
end
