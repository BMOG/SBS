class CreateHexagons < ActiveRecord::Migration
  def change
    create_table :hexagons do |t|
      t.integer :grid_id
      t.integer :number
      t.string  :geography
      t.integer :altitude
      t.boolean :summit
      t.text    :sides

      t.timestamps
    end

  end
end
