class User < ActiveRecord::Base
	attr_accessible :active, :admin, :deleted, :email, :hashed_password, :last_login_date, :last_login_server, :lastname, :name, :profile, :salt, :session_token
	
	has_many :homeworks
	has_many :participations
	has_many :email_activations
	has_many :password_recoveries
	
	def to_xml(options={})
		options[:except] ||= [:hashed_password, :salt]
		super(options)
   end

   # Exclude password info from json output.
   def to_json(options={})
		options[:except] ||= [:hashed_password, :salt]
		super(options)
   end
end
