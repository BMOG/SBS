class CreateGrids < ActiveRecord::Migration
  def change
    create_table :grids do |t|
      t.integer :scenario_id
      t.integer :picture_width
      t.integer :picture_height
      t.integer :maxcol
      t.integer :maxlin
      t.integer :hex_side_length

      t.timestamps
    end
    
    add_index :grids, :scenario_id
  
  end
end
