class AddScreensizeToContexts < ActiveRecord::Migration
  def change
    add_column :contexts, :height, :integer
    add_column :contexts, :width, :integer
  end
end
