class EmailActivation < ActiveRecord::Base
  attr_accessible :expires_at, :token, :user_id
end
