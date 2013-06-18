#encoding: utf-8
require 'digest/sha1'
require 'open-uri'
require 'rubygems'
require 'zip/zip'
require 'tempfile'

class HomeworksController < ApplicationController
  # GET /homeworks
  # GET /homeworks.json
  def index
	if(filters)
	#Revisamos si incio sesion
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
    @homeworks = Homework.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @homeworks }
      flash[:active_tab] = "homeworks"
    end
  end

  # GET /homeworks/1
  # GET /homeworks/1.json
  def show
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
    #Si no es admin, dueño o participante, chao
    if( (User.find(session[:user_id]).admin) || (Homework.find(params[:id]).user.id == session[:user_id]) || (Participation.exists?(:user_id => session[:user_id])) )
      @homework = Homework.find(params[:id])
      @random = rand(10000)
      @random_hash = Digest::SHA1.hexdigest(@random.to_s)
      @invitations = Participation.find_all_by_homework_id(@homework.id)
      respond_to do |format|
          format.html # show.html.erb
          format.json { render json: @homework }
        end
    else
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
	end
  
    
  end

  # GET /homeworks/new
  # GET /homeworks/new.json
  def new
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end

    @homework = Homework.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @homework }
    end
  end

  # GET /homeworks/1/edit
  def edit
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	#Revisamos que sea su tarea
		if(Homework.find(params[:id]).user.id != session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
    @homework = Homework.find(params[:id])
  end

  # POST /homeworks
  # POST /homeworks.json
  def create
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
	end
    #Contamos las tareas para asegurarnos de que no tenga sobre 20
    userid = session[:user_id]
    if(User.find(userid).homeworks.count > 20)
      flash[:error] = "Lo sentimos, no puede tener una cantidad mayor a 20 buzones"
      redirect_to home_path
    else
      @homework = Homework.new(params[:homework])
      @homework.user_id = userid
	  
	  uploaded_io = params["file"]
	  begin
		@homework.filename = uploaded_io.original_filename
	  rescue
		@homework.filename = params["file"].to_s
	  end
	  
      respond_to do |format|
          if @homework.save
			
      begin
			 directory = Dir::pwd + "/shared_files/#{userid.to_s}"
			 Dir::mkdir(directory) unless File.exists?(directory)
			 directory = Dir::pwd + "/shared_files/#{userid.to_s}/#{@homework.id.to_s}"
			 Dir::mkdir(directory) unless File.exists?(directory)

        File.open(Rails.root.join('shared_files', "#{userid.to_s}/#{@homework.id.to_s}", @homework.filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
			rescue
        #Este rescue existe para capturar el error de permisos, el cual no afecta el flujo del programa (pues los buzones se crean igual).
      end
			
			
            format.html { redirect_to @homework, notice: 'Buzón creado exitosamente' }
            format.json { render json: @homework, status: :created, location: @homework }
          else
            format.html { render action: "new" }
            format.json { render json: @homework.errors, status: :unprocessable_entity }
          end
       end
    end

  end

  # PUT /homeworks/1
  # PUT /homeworks/1.json
  def update
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
    #Revisamos que sea su tarea
    if(Homework.find(params[:id]).user.id != session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
	end
    @homework = Homework.find(params[:id])

    respond_to do |format|
      if @homework.update_attributes(params[:homework])
        format.html { redirect_to @homework, notice: 'Elemento actualizado exitosamente' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @homework.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /homeworks/1
  # DELETE /homeworks/1.json
  def destroy
	if(filters)
	#Revisamos si incio sesion
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
    #Revisamos que sea su tarea
    if(Homework.find(params[:id]).user.id != session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
	end
    @homework = Homework.find(params[:id])
    #Antes de borrar eliminamos todo lo asociado
    participations = Participation.find_all_by_homework_id(params[:id])
    participations.each do |p|
      #Borrar achivos subidos
      p.destroy
    end
    
    @homework.destroy
    flash[:error] = "El buzón fue eliminado con éxito"
    redirect_to home_path
  end

  #Invite people to this homework
  def invite
    if(filters)
  #Revisamos si incio sesion
    if(!session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
  #Revisamos que sea su tarea
    if(Homework.find(params[:id]).user.id != session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
  end

    if(!Homework.exists?(:id=>params[:id]))
      flash[:error] = "Buzón inexistente"
      redirect_to home_path
      return
    end
    @homework = Homework.find(params[:id])
    render "invite.html.erb"
  end

  def saveinvites
    if(filters)
  #Revisamos si incio sesion
    if(!session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
  #Revisamos que sea su tarea
    if(Homework.find(params[:id]).user.id != session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
  end

   if(!Homework.exists?(:id=>params[:id]))
      flash[:error] = "Buzón inexistente"
      redirect_to home_path
      return
    end

	if(!params[:email]) 
		params[:email] = Array.new
	end
	
	if(params[:file])
		uploaded_io = params["file"]
		uploaded_io.read.each_line{ |s|
			params[:email].push([10,s.strip()])
			#flash[:succes] += s
		}
	end
	
    if(params[:email].nil? || params[:email].empty?)
      @homework = Homework.find(params[:id])
      flash[:error] = "Debe ingresar al menos un invitado"
      render "invite.html.erb"
      return
    else
      #Revisar mails
      params[:email].each do |g|
        if(!g[1].match(/\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/))
          @homework = Homework.find(params[:id])
          flash[:error] = "#{g[1]} no es un correo correcto"
          render "invite.html.erb"
          return
        end
      end
      counter = 0
      existed = false
      @homework = Homework.find(params[:id])
      params[:email].each do |g|
          if(!User.exists?(:email => g[1].delete(' '), :deleted => 0))
            @user = User.new
            @user.email = g[1].delete(' ')
            @user.name = "Firstname"
            @user.lastname = "Lastname"
            @user.admin = false
            @user.active = false;
            #Guardamos el hash
            @user.salt = SecureRandom.hex
            @hashed = @user.salt
            100.times do
              @hashed = Digest::SHA1.hexdigest(@hashed)
            end
            @user.hashed_password = @hashed

            #Seteamos los valores por defecto
            @user.session_token = ""
            @user.last_login_date = Time.new
            @user.last_login_server = "desaweb1.ing.puc.cl"

            @user.deleted = 0
            @user.save
            
            @hu = Participation.new
            @hu.user_id = @user.id
            @hu.homework_id = @homework.id
            @hu.save
			
			@activation = EmailActivation.new
			@activation.user_id = @user.id
			@activation.token = SecureRandom.hex
			@activation.expires_at = DateTime.now + 2.days
			@activation.save
            
			UserMailer.first_invitation_event(@user, @activation).deliver
			
            #begin
             # UserMailer.first_invitation_email(@homework, @user).deliver
            #rescue
            #end
          else
            #Revisar que no haya sido invitado
            @user = User.find_by_email_and_deleted(g[1].delete(' '), 0)
            if(!Participation.exists?(:user_id => @user.id, :homework_id => @homework.id))
               @hu = Participation.new
                @hu.user_id = @user.id
                @hu.homework_id = @homework.id
                @hu.save
                #begin
                UserMailer.invitation_event(@user, @homework).deliver
                #rescue
                #end
            else
              existed = true
            end
            
           
          end
          counter = counter+1
        end
        if(counter == 1)
          message = "#{counter} usuario invitado exitosamente"
        else
          message = "#{counter} usuarios invitados exitosamente"
        end

        
        if(existed)
          if(counter == 1)
            message = "El usuario ya fue invitado, por lo que fue omitido"
          else
           message += " (Algunos usuarios ya fueron invitados, por lo que fueron omitidos)"
          end
          
        end
         respond_to do |format|
            format.html { redirect_to @homework, notice: message }
            format.json { render json: @homework, status: :created, location: @homework }
        end
    end
  end

	def upload
		@homework = Homework.find(params[:homework_id])
		@user = User.find(session[:user_id])
		@participation = Participation.where(:homework_id => @homework.id, :user_id => @user.id).first

		if(params[:captcha_random_hash] != Digest::SHA1.hexdigest(params[:captcha_random]))
			flash[:error] = "Error en el captcha"
			redirect_to @homework
			return
		end
		
		@captcha_value = open("http://captchator.com/captcha/check_answer/#{params[:captcha_random]}/#{params[:captcha]}").read.to_i
		if(@captcha_value != 1)
			flash[:error] = "Error en el captcha"
			redirect_to @homework
			return
		end
		
		
		if (!@participation)
			flash[:error] = "Acceso denegado"
			redirect_to home_path
			return
		end
		
		total_size = 0
		
		for i in 0..params[:file_count].to_i
			begin
				uploaded_io = params["file_#{i}"]
				total_size = total_size + uploaded_io.size
			rescue
			end
		end
	
		if (total_size / 1024000 > 50)
			flash[:error] = "Lo sentimos, su entrega no puede superar los 50 MB"
			redirect_to @homework
			return
		end
	
		@version = 1;

		if(Archive.where(:participation_id => @participation.id).first)
			archives = Archive.where(:participation_id => @participation.id)
			archives.each do |a|
				if(a.version >= @version)
					@version = a.version + 1
				end
			end
		end

		directory = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}"
		Dir::mkdir(directory) unless File.exists?(directory)
		directory = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}/#{@homework.id.to_s}"
		Dir::mkdir(directory) unless File.exists?(directory)
		directory = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}/#{@homework.id.to_s}/#{@participation.user_id.to_s}"
		Dir::mkdir(directory) unless File.exists?(directory)
		directory = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}/#{@homework.id.to_s}/#{@participation.user_id.to_s}/#{@version.to_s}"
		Dir::mkdir(directory) unless File.exists?(directory)
		
		uploaded_count = 0;
		file_path = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}/#{@homework.id.to_s}/#{@participation.user_id.to_s}"
		zipfile_name = Dir::pwd + "/shared_files/#{@homework.user_id.to_s}/#{@homework.id.to_s}/#{@participation.user_id.to_s}/#{@version.to_s}.zip"
		
		for i in 0..params[:file_count].to_i
			@archive = Archive.new
			@archive.version = @version
			@archive.participation_id = @participation.id
			@archive.ip = request.remote_ip
			if(request.env["HTTP_X_FORWARDED_FOR"])
				@archive.ip = request.env["HTTP_X_FORWARDED_FOR"]
			end
			begin
				uploaded_io = params["file_#{i}"]
				@archive.name = uploaded_io.original_filename
				File.open(Rails.root.join('shared_files', "#{@homework.user_id.to_s}/#{@homework.id.to_s}/#{@participation.user_id.to_s}/#{@version.to_s}", uploaded_io.original_filename), 'wb') do |file|
					file.write(uploaded_io.read)
				end
				@archive.save
				uploaded_count = uploaded_count + 1
			
				Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
					zipfile.add(@archive.name, file_path + '/' + @archive.name)
				end
			rescue
			end
			
		end
		flash[:succes] = "Subidos #{uploaded_count} archivos exitosamente como v #{@version}"
		redirect_to @homework
	end
  def manageinvites
    if(filters)
    #Revisamos si incio sesion
      if(!session[:user_id])
        flash[:error] = "Acceso denegado"
        redirect_to home_path
        return
      end
    #Revisamos que sea su tarea
      if(Homework.find(params[:id]).user.id != session[:user_id])
        flash[:error] = "Acceso denegado"
        redirect_to home_path
        return
      end
    end
     if(!Homework.exists?(:id=>params[:id]))
      flash[:error] = "Buzón inexistente"
      redirect_to home_path
      return
    end

    @homework = Homework.find(params[:id])
    @invitations = Participation.find_all_by_homework_id(@homework.id)
    render "delete_invitation.html.erb"
  end

  def uninvite
    if(filters)
  #Revisamos si incio sesion
    if(!session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
    if(!Homework.exists?(:id=>params[:homework_id]))
      flash[:error] = "Buzón inexistente"
      redirect_to home_path
      return
    end
  #Revisamos que sea su tarea
    if(Homework.find(params[:homework_id]).user.id != session[:user_id])
      flash[:error] = "Acceso denegado"
      redirect_to home_path
      return
    end
    end


    #Get the parameter
    @homework = Homework.find(params[:homework_id])

    if(!Participation.exists?(:homework_id => @homework.id, :user_id => params[:user_id]))
      flash[:error] = "Ese usuario no pertenece a esta tarea"
      redirect_to home_path
      return
    end
    user = User.find(params[:user_id])
    participation = Participation.find_by_homework_id_and_user_id(@homework.id, user.id)
    @invitations = Participation.find_all_by_homework_id(@homework.id)
    participation.destroy
    #Redirigir
    flash[:succes] = "El usuario #{user.name + " " + user.lastname} fue eliminado de esta tarea y ya no puede participar en ella."
     redirect_to "/homeworks/manageinvites/#{@homework.id}"
  end

  def viewfiles
     if(filters)
    #Revisamos si incio sesion
      if(!session[:user_id])
        flash[:error] = "Acceso denegado"
        redirect_to home_path
        return
      end
      if(!Homework.exists?(:id=>params[:homework_id]))
        flash[:error] = "Buzón inexistente"
        redirect_to home_path
        return
      end
    end

    #Revisamos nivel de acceso
    #Si es administrador, el usuario que está viendo es el entregado
    @user = User.find(session[:user_id])
    if(@user.admin)
        @user = User.find(params[:user_id])
    end
    @homework = Homework.find(params[:homework_id])
    
    #Obtenemos todos los archivos
    @archives = Array.new
    participations = Participation.find_all_by_user_id_and_homework_id(@user.id, @homework.id)
    participations.each do |p|
      #Obtener todos los archivos
      all_archives = Archive.find_all_by_participation_id(p.id)
      all_archives.each do |ar|
        @archives.push(ar)
      end
    end
    @archives.uniq!
    @archives.sort_by{|a| a[:version]}
    render "file_show.html.erb"
  end
  
	def example_file
		send_data("ejemplo1@mail.com\r\nejemplo2@mail.com\r\nejemplo3@mail.com", :filename => "ejemplo.txt", :type => "application/txt")
	end
  
end
