# == Schema Information
#
# Table name: scenarios
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  definition :text
#  created_at :datetime
#  updated_at :datetime
#

class Scenario < ActiveRecord::Base
  attr_accessible :name, :definition
    
  validates :name, presence: true, length: { maximum: 50 }
  validates :definition, presence: true
end
