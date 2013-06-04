require 'digest/sha1'
require 'open-uri'

class HomeController < ApplicationController

	def index
		#Si se necesita calcular un random para el login_2
		if (!session[:user_id])
			if (session[:login_error_count])
				if (session[:login_error_count].to_i >= 3)
					@random = rand(10000)
					@random_hash = Digest::SHA1.hexdigest(@random.to_s)
				end
			end
		else
			@user = User.find(session[:user_id])
			@my_homeworks = @user.homeworks
			@other_homeworks = Homework.all	
		end
		flash[:active_tab] = "home"
		render "index.html.erb"
	end
	
	def login
		#Revisamos que no este ya inciado sesion
		if(session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		
		#Revisamos si existe el mail y no este eliminado
		if(!User.exists?(:email => params[:email], :deleted => 0, :active => true))
			flash[:error] = "Error al iniciar sesion"
			if(!session[:login_error_count])
				session[:login_error_count] = 1
			else
				session[:login_error_count] = session[:login_error_count].to_i + 1
			end
			redirect_to home_path
			return
		end
		
		#Revisamos si la clave corresponde
		user = User.find_by_email_and_deleted(params[:email], 0)
		hashed = params[:password] + user.salt
		100.times do
			hashed = Digest::SHA1.hexdigest(hashed)
		end
		if(hashed != user.hashed_password)
			flash[:error] = "Error al iniciar sesion"
			if(!session[:login_error_count])
				session[:login_error_count] = 1
			else
				session[:login_error_count] = session[:login_error_count].to_i + 1
			end
			redirect_to home_path
			return
		end
		
		#Iniciamos la sesion
		session[:user_id] = user.id
		session[:login_error_count] = nil
		
		#Guardamos los nuevos datos de coneccion
		user.last_login_date = Time.new.advance(:hours => -4)
		#user.last_login_server = request.remote_ip
		#if(request.env["HTTP_X_FORWARDED_FOR"])
		#	user.last_login_server = request.env["HTTP_X_FORWARDED_FOR"]
		#end
		user.last_login_server = "desaweb1.ing.puc.cl"
		user.save
		
		flash[:succes] = "Bienvenido #{user.name + " " + user.lastname}"
		redirect_to home_path
	end
	
	def login_2
		#Revisamos que no este ya inciado sesion
		if(session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		
		#Revisamos que no hayan modificado los hidden
		if(params[:captcha_random_hash] != Digest::SHA1.hexdigest(params[:captcha_random]))
			flash[:error] = "Error al iniciar sesion"
			session[:login_error_count] = session[:login_error_count].to_i + 1
			redirect_to home_path
			return
		end
		
		#Revisamos que el captcha este bueno
		@captcha_value = open("http://captchator.com/captcha/check_answer/#{params[:captcha_random]}/#{params[:captcha]}").read.to_i
		if(@captcha_value != 1)
			flash[:error] = "Error al iniciar sesion"
			session[:login_error_count] = session[:login_error_count].to_i + 1
			redirect_to home_path
			return
		end
		
		#Revisamos que exista el mail y no este eliminado
		if(!User.exists?(:email => params[:email], :deleted => 0, :active => true))
			flash[:error] = "Error al iniciar sesion"
			session[:login_error_count] = session[:login_error_count].to_i + 1
			redirect_to home_path
			return
		end
		
		#Revisamos la contrasena
		user = User.find_by_email_and_deleted(params[:email], 0)
		hashed = params[:password] + user.salt
		100.times do
			hashed = Digest::SHA1.hexdigest(hashed)
		end
		if(hashed != user.hashed_password)
			flash[:error] = "Error al iniciar sesion"
			session[:login_error_count] = session[:login_error_count].to_i + 1
			redirect_to home_path
			return
		end
		
		#Iniciamos la sesion
		session[:user_id] = user.id
		session[:login_error_count] = nil
		
		#Guardamos los nuevos datos de coneccion
		user.last_login_date = Time.new.advance(:hours => -4)
		#user.last_login_server = request.remote_ip
		#if(request.env["HTTP_X_FORWARDED_FOR"])
		#	user.last_login_server = request.env["HTTP_X_FORWARDED_FOR"]
		#end
		user.last_login_server = "desaweb1.ing.puc.cl"
		user.save
		
		flash[:succes] = "Bienvenido #{user.name + " " + user.lastname}"
		redirect_to home_path
		
	end

	def logout
		#Revisamos que este logeado
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		
		#borramos la sesion
		reset_session
		flash[:succes] = "Sesion cerrada exitosamente"
		redirect_to home_path
	end
	
	def admin
		if(filters)
			if(!session[:user_id])
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
			if(!User.find(session[:user_id]).admin)
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
		end
		flash[:active_tab] = "admin"
		return
		
	end
	
end
