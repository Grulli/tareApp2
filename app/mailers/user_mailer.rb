class UserMailer < ActionMailer::Base
	default from: "tareApp@desaweb1.ing.puc.cl"
	
	def welcome_email(user, activation)
		@user = user
		@activation = activation
		mail(:to => user.email, :subject => "Bienvenido a tareApp")
	end
	
	def password_recovery_email(user, recovery)
		@user = user
		@recovery = recovery
		mail(:to => user.email, :subject => "Recuperacion de contrasena de tareApp")
	end
	
	def invitation_event(user, event)
		@user = user
		@event = event
		mail(:to => user.email, :subject => "Te han invitado a #{@event.name}")
	end
end
