class ApplicationController < ActionController::Base
  protect_from_forgery
	def filters
		return true
	end
end
