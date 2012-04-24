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
#  created_at     :datetime
#  updated_at     :datetime
#  height         :integer
#  width          :integer
#

class Context < ActiveRecord::Base
  attr_accessible :action
  
  # sw: scenario width
  def sw
    return width - 20
  end

  # sh: scenario height
  def sh
    return height - 20
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
