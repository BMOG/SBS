# == Schema Information
#
# Table name: contexts
#
#  id             :integer         not null, primary key
#  remember_token :string(255)
#  user_id        :integer
#  game_id        :integer
#  scenario_id    :integer
#  current_turn   :integer
#  current_unit   :integer
#  current_hex    :integer
#  action         :string(255)
#  scale          :float
#  windows_width  :integer
#  windows_height :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class Context < ActiveRecord::Base
  attr_accessible :action
  
  # sw: scenario width
  def sw
    return windows_width - 20
  end

  # sh: scenario height
  def sh
    return windows_height - 20
  end
  
  # cw: canvas width
  def cw
    return (sw * 80 / 100).floor
  end

  # ch: canvas height
  def ch
    return sh - 50
  end

end
