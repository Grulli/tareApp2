require 'open-uri'
require 'uri'
require 'json'
require 'net/https'
require 'securerandom'

class OauthController < ApplicationController

	def new_facebook
		facebook_settings = YAML::load(File.open("config/oauth.yml"))
		redirect_to "https://graph.facebook.com/oauth/authorize?client_id=#{facebook_settings['application_id']}&redirect_uri=http://desaweb1.ing.puc.cl/facebook_login&scope=email"
	end
	
	def facebook_oauth_callback
		if not params[:code].nil?
			facebook_settings = YAML::load(File.open("config/oauth.yml"))
			callback = "#{APP_URL}/facebook_credentials/facebook_oauth_callback"
			url = URI.parse("https://graph.facebook.com/oauth/access_token?client_id=#{facebook_settings[RAILS_ENV]['application_id']}&redirect_uri=#{callback}&client_secret=#{facebook_settings[RAILS_ENV]['secret_key']}&code=#{CGI::escape(params[:code])}")
			http = Net::HTTP.new(url.host, url.port)
			http.use_ssl = (url.scheme == 'https')
			tmp_url = url.path+"?"+url.query
			request = Net::HTTP::Get.new(tmp_url)
			response = http.request(request)     
			data = response.body
			access_token = data.split("=")[1]
			url = URI.parse("https://graph.facebook.com/me?access_token=#{CGI::escape(access_token)}")
			http = Net::HTTP.new(url.host, url.port)
			http.use_ssl = (url.scheme == 'https')
			tmp_url = url.path+"?"+url.query
			request = Net::HTTP::Get.new(tmp_url)
			response = http.request(request)        
			user_data = response.body
			user_data_obj = JSON.parse(user_data)
			flash[:notice] = 'Facebook successfully connected.'
			@social_credential = SocialCredential.create_or_find_new_facebook_cred(access_token, session['rsecret'])
		end
	end
	
	def facebook_login
	
		if params[:code]
			@contents = open("https://graph.facebook.com/oauth/access_token?client_id=447261195351468&redirect_uri=http://desaweb1.ing.puc.cl/facebook_login&client_secret=0beaff15109c00b110fa3cf6663b9d5c&code=#{params[:code]}").read
			@access_token = @contents[@contents.index('=')+1..@contents.index('&')-1]
		
			@resp = open("https://graph.facebook.com/me?access_token=#{@access_token}").read
			@result = JSON.parse(@resp)
		
			if @result['email']
				if User.exists?(:mail => @result['email'], :deleted => 0)
					user = User.find_by_mail_and_deleted(@result['email'],0)
					if user.active
						session[:user_id] = user.id
						@user = User.find_by_mail(@result['email'])
						flash[:succes] = "Sesion iniciada exitosamente"
						return redirect_to home_path
					else
						flash[:error] = "So ha activado su cuenta"
						return redirect_to home_path
					end
				else
					@user = User.new
					@user.mail = @result['email']
					@user.salt = SecureRandom.hex
					@user.hashed_password = SecureRandom.hex
					@user.active = false
					@user.admin = false
					@user.deleted = 0
					@user.lastname = @result['last_name']
					@user.name = @result['first_name']
					@user.profile = "<h2>#{@user.name} #{@user.lastname}</h2>"
					
					if @user.save
						
						@activation = EmailActivation.new
						@activation.user_id = @user.id
						@activation.token = SecureRandom.hex
						@activation.expires_at = DateTime.now + 2.days
						@activation.save
						UserMailer.welcome_email(@user,@activation).deliver
		
						flash[:succes] = "Bienvenido a tareApp2 #{@user.name + " " + @user.lastname}, revise su email para activar su cuenta"
						return redirect_to home_path
					else
						flash[:error] = "No se pudo ingresar"
					end
				end
			else
				flash[:error] = "No se pudo ingresar"
			end
		end
		redirect_to home_path
	end

end
