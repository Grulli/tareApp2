require 'digest/sha1'
require 'securerandom'

class UsersController < ApplicationController
  # GET /users
  # GET /users.json
  def index
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	
		#Revisamos si es admin
		if(!User.find(session[:user_id]).admin || !User.find(session[:user_id]).active)
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
	
    @users = User.all
	
	if(params[:status])
		if(params[:status] == "active")
			@users = User.find_all_by_active_and_deleted(true,0)
		elsif(params[:status] == "deleted")
			@users = User.find(:all, :conditions =>['deleted > 0'])
		end
	end

	flash[:active_tab] = "admin"
	
	#if(params[:email] or params[:name] or params[:lastname] or params[:admin] or params[:sufijo] or params[:date] or params[:date_1] or params[:date_2])
	if(params[:commit] == "Buscar usuario")
		flash.now[:succes] = "Buscando usuarios:"
		@conditions = Array.new
		if(params[:status] == "active")
			@conditions.push("deleted = 0")
		elsif(params[:status] == "deleted")
			@conditions.push("deleted > 0")
		end
		if (params[:sufijo] != "")
			@conditions.push("email LIKE \"%%#{params[:sufijo]}\"")
		elsif (params[:email] != "")
			@conditions.push("email LIKE \"#{params[:email]}\"")
		end
		if (params[:date] != "")
			@conditions.push("created_at LIKE #{params[:date]}")
		elsif ((params[:date_1] != "") and (params[:date_2] != ""))
			@date1 = "#{params[:date_1]}"#  +"%%" + "T00:00:00Z"
			@date2 = "#{params[:date_2]}"#  + "%%" + "T23:59:59Z"
			@conditions.push("created_at > #{@date1} AND created_at < #{@date2}")
		end
		
		if (params[:name] != "")
			@conditions.push("name LIKE \"%%#{params[:name]}%%\"")
		end
		if (params[:last_name] != "")
			@conditions.push("lastname LIKE \"%%#{params[:lastname]}%%\"")
		end
		
		
		@users = User.find(:all, :conditions=>@conditions)
		
		if (params[:admin])
			@admins = Array.new
			@users.each do |u|
				if(u.admin)
					@admins.push(u)
				end
			end
			@users = @admins
		end
		
	end
	
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
	if(filters)
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		if(!User.find(session[:user_id]).admin || !User.find(session[:user_id]).active)
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
    @user = User.find(params[:id])

	flash[:active_tab] = "admin"
	
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
	if(filters)
		#Revisamos que no haya iniciado sesion
		if(session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
  
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit #Modificado para que solo pueda cambiar nombre y apellido
	if(filters)
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		if(session[:user_id].to_i != params[:id].to_i and !User.find(session[:user_id]).admin)
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
    @user = User.find(params[:id])
	@hashed_id = Digest::SHA1.hexdigest(@user.id.to_s)
  end

  # POST /users
  # POST /users.json
  def create
	if(filters)
	#Revisamos que no haya iniciado sesion
		if(session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
	
    @user = User.new(params[:user])
	
	#Revisamos que el mail no este ocupado por una cuenta activa
	if(User.exists?(:email => @user.email, :deleted => 0))
		flash[:form_error] = "Correo electronico ya inscrito"
		redirect_to new_user_path
		return
	end
	
	#Que la contrasena y la confirmacion sean iguales
	if !(params[:password] == params[:password_confirmation] and params[:password].length >= 6)
		flash[:form_error] = "Error en la contrasena"
		respond_to do |format|
			format.html { render action: "new" }
		end
		return
	end
	
	#Guardamos el hash
	@user.salt = SecureRandom.hex
	@hashed = params[:password] + @user.salt
	100.times do
		@hashed = Digest::SHA1.hexdigest(@hashed)
	end
	@user.hashed_password = @hashed

	#Seteamos los valores por defecto
	@user.deleted = 0
	@user.admin = false
	@user.session_token = ""
	@user.last_login_date = Time.new.advance(:hours => -4)
	#@user.last_login_server = request.remote_ip
	@user.last_login_server = "desaweb1.ing.puc.cl"
	
	#TODO: Aca enviar mail y setear active en false
	@user.active = true
	
	#if(request.env["HTTP_X_FORWARDED_FOR"])
	#	@user.last_login_server = request.env["HTTP_X_FORWARDED_FOR"]
	#end
	@user.profile = "<h2>#{@user.name} #{@user.lastname}</h2>"
	if(User.all.count < 1)
		@user.admin = true
	end

	#Se guarda
    respond_to do |format|
      if @user.save
		
		@activation = EmailActivation.new
		@activation.user_id = @user.id
		@activation.token = SecureRandom.hex
		@activation.expires_at = DateTime.now + 2.days
		@activation.save
		UserMailer.welcome_email(@user,@activation).deliver
		
		flash[:succes] = "Bienvenido a tareApp2 #{@user.name + " " + @user.lastname}"
		session[:user_id] = @user.id
        format.html { redirect_to home_path }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update #Modificado para que solo pueda cambiar nombre y apellido (y admin cuando el que hace el cambio sea un admin)
	if(!session[:user_id])
		lash[:error] = "Acceso denegado"
		redirect_to home_path
		return
	end
  
	if(!params[:user_id] or !params[:hashed_id] or !params[:name] or !params[:lastname])
		flash[:error] = "Error"
		redirect_to home_path
		return
	end
	
	if(params[:admin] and !User.find(session[:user_id]).admin)
		flash[:error] = "Error"
		redirect_to home_path
		return
	end
	
	if(Digest::SHA1.hexdigest(params[:user_id].to_s) != params[:hashed_id])
		flash[:error] = "Error"
		redirect_to home_path
		return
	end
	
    @user = User.find(params[:user_id])
	@user.name = params[:name]
	@user.lastname = params[:lastname]
	
	if(User.find(session[:user_id]).admin and session[:user_id] != params[:user_id])
		if(params[:admin])
			@user.admin = true
		else
			@user.admin = false
		end
	end
	
	
	@user.save
	
	flash[:succes] = "Datos actualizados"
	
	if(User.find(session[:user_id]).admin)
		redirect_to admin_path
		return
	end
	
	redirect_to "/profile/#{@user.id}"
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy #Borrado logico
	
	if(filters)
	#Revisamos que esta logeado
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	
		#Revisamos que sea admin
		if(!User.find(session[:user_id]).admin || !User.find(session[:user_id]).active)
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
	
	#Revisamos que no se este desactivando a si mismo (es otro metodo)
	if(session[:user_id].to_i == params[:id].to_i)
		flash[:error] = "No se puede desactivar a si mismo"
		redirect_to users_path
		return
	end
	
	#Buscamos el siguiente deleted mas alto
	user = User.find(params[:id])
	users = User.find_all_by_email(user.email)
	users.sort! { |a,b| a.deleted <=> b.deleted }
	
	#le asignamos el valor de deleted mas alto
	user.deleted = users.last.deleted + 1
	user.save
	
	flash[:succes] = "Desactivado el usuario #{user.name + " " + user.lastname}"
	redirect_to users_path
	
    #@user = User.find(params[:id])
    #@user.destroy

    #respond_to do |format|
	#	format.html { redirect_to users_url }
    #	format.json { head :no_content }
    #end
  end

	def profile #El perfil personalizado de cada usuario
		if(filters)
			if(!session[:user_id])
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
			if(!User.find(session[:user_id]).active)
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
		end
		flash[:active_tab] = "profile"
		@user = User.find(params[:user_id])
	end

	def edit_profile #Muestra la vista para editar el perfil
		if(filters)
			if(!session[:user_id])
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
			if(!User.find(session[:user_id]).active)
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
		end
		@user = User.find(session[:user_id])
	end
	
	def edit_profile_post #metodo post que recibe los cambios en el perfil
		if(filters)
			if(!session[:user_id])
				flash[:error] = "Acceso denegado"
				redirect_to home_path
				return
			end
		end
		
		if(!params[:profile])
			flash[:error] = "Error"
			redirect_to edit_profile_path
			return
		end
		
		user = User.find(session[:user_id])
		user.profile = params[:profile]
		user.save
		flash[:succes] = "Perfil actualizado exitosamente"
		redirect_to "/profile/#{session[:user_id]}"
	end
	
	def change_password #Muestra la vista para cambiar la pagina
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		@user = User.find(session[:user_id])
	end
	
	def change_password_post #Metodo post para hacer los cambios
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		if(!params[:old_password] || !params[:new_password] || !params[:new_password_confirmation])
			flash[:error] = "Error"
			redirect_to change_password_path
			return
		end
		
		@user = User.find(session[:user_id])
		@hashed = params[:old_password] + @user.salt
		100.times do
			@hashed = Digest::SHA1.hexdigest(@hashed)
		end
		
		if(@hashed != @user.hashed_password)
			flash[:error] = "Contrasena incorrecta"
			redirect_to change_password_path
			return
		end
		
		if(params[:new_password] != params[:new_password_confirmation])
			flash[:error] = "Nueva contrasena no es igual a la confirmacion"
			redirect_to change_password_path
			return
		end
		
		@user.salt = SecureRandom.hex
		@hashed = params[:new_password] + @user.salt
		100.times do
			@hashed = Digest::SHA1.hexdigest(@hashed)
		end
		@user.hashed_password = @hashed
		@user.save
		
		flash[:succes] = "Contrasena actualizada exitosamente"
		
		redirect_to "/profile/#{session[:user_id]}"
		
	end
	
	def admin_create
		if (filters)
			if(!session[:user_id])
				flash[:error] = "Acceso Denegado"
				redirect_to home_path
				return
			end
			if(!User.find(session[:user_id]).admin)
				flash[:error] = "Acceso Denegado"
				redirect_to home_path
				return
			end
		end
		if(User.exists?(:email => params[:email], :deleted => 0))
			flash[:error] = "Ya existe una cuenta con ese email"
			redirect_to users_path
			return
		end
		if(params[:password] != params[:password_confirmation])
			flash[:error] = "Error en la contrasena"
			redirect_to users_path
			return
		end
		
		user = User.new
		user.email = params[:email]
		user.name = params[:name]
		user.lastname = params[:lastname]
		user.deleted = 0
		
		#TODO: activar con mail
		user.active = true

		
		user.salt = SecureRandom.hex
		hashed = params[:password] + user.salt
		100.times do
			hashed = Digest::SHA1.hexdigest(hashed)
		end
		user.hashed_password = hashed
		
		if(params[:admin])
			user.admin = true
		else
			user.admin = false
		end
		
		user.save
		
		flash[:succes] = "Usuario creado exitosamente"
		redirect_to users_path
		return
		
	end
	
end
