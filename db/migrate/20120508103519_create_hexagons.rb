class CreateHexagons < ActiveRecord::Migration
  def change
    create_table :hexagons do |t|
      t.integer :scenario_id
      t.integer :number
      t.string  :geography
      t.integer :altitude
      t.boolean :summit
      t.text    :sides

      t.timestamps
    end

    add_index :scenario_id, :number, unique: true   

  end
end
