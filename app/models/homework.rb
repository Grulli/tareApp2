class Homework < ActiveRecord::Base
	attr_accessible :active, :description, :expires_at, :filename, :name, :user_id
	
	belongs_to :user
	
end
