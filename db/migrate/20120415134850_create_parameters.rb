class CreateParameters < ActiveRecord::Migration
  def change
    create_table :parameters do |t|
      t.integer :hsl

      t.timestamps
    end
  end
end