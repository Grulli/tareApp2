class Archive < ActiveRecord::Base
  attr_accessible :ip, :name, :participation_id, :version
  
	belongs_to :participation
  
end
