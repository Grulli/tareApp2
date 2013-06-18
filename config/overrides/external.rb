class External < ActiveRecord::Base
  self.abstract_class = true
  ActiveRecord::Base.establish_connection "remote"
end