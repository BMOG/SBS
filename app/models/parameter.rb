# == Schema Information
#
# Table name: parameters
#
#  id         :integer         not null, primary key
#  hsl        :integer
#  created_at :datetime
#  updated_at :datetime
#

class Parameter < ActiveRecord::Base
  attr_accessible :hsl

  validates :hsl, presence: true
  
  # th: hexagon triangle height
  def th
    return ((self.hsl - 0.30) * Math.sin(Math::PI / 6))
  end

  # rhl: hexagon rectangle half length
  def rhl
    return ((self.hsl - 0.15) * Math.cos(Math::PI / 6)) 
  end   

  # - fh: hexagon full height
  def fh
    return self.hsl + 2 * self.th
  end

  # - fw: hexagon full width 
  def fw
    return 2 * self.rhl
  end  
    
end
