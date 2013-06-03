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
	@hashed = @user.salt + params[:password]
	10.times do
		@hashed = Digest::SHA1.hexdigest(@hashed)
	end
	@user.hashed_password = @hashed

	#Seteamos los valores por defecto
	@user.deleted = 0
	@user.admin = false
	@user.session_token = ""
	@user.last_login_date = Time.new.advance(:hours => -4)
	@user.last_login_server = request.remote_ip
	
	
	#TODO: Aca enviar mail y setear active en false
	@user.active = true
	
	if(request.env["HTTP_X_FORWARDED_FOR"])
		@user.last_login_server = request.env["HTTP_X_FORWARDED_FOR"]
	end
	@user.profile = "<h2>#{@user.name} #{@user.lastname}</h2>"
	if(User.all.count < 1)
		@user.admin = true
	end
	
	#Se guarda
    respond_to do |format|
      if @user.save
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
  def update #Modificado para que solo pueda cambiar nombre y apellido
	if(filters)
		flash[:error] = "Acceso denegado"
		redirect_to home_path
		return
	end
	
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
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
		@hashed = @user.salt + params[:old_password]
		10.times do
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
		@hashed = @user.salt + params[:new_password]
		10.times do
			@hashed = Digest::SHA1.hexdigest(@hashed)
		end
		@user.hashed_password = @hashed
		@user.save
		
		flash[:succes] = "Contrasena actualizada exitosamente"
		
		redirect_to "/profile/#{session[:user_id]}"
		
	end
	
end
