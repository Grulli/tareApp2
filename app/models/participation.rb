class Participation < ActiveRecord::Base
  attr_accessible :homework_id, :user_id
  
	has_many :archives
	belongs_to :user
	belongs_to :homework
end
