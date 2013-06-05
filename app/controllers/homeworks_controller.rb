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
	end
  
    @homeworks = Homework.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @homeworks }
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
	end
  
    @homework = Homework.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @homework }
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
    #Contamos las tareas para asegurarnos de que no tenga más de 20
    userid = session[:user_id]
    if(User.find(userid).homeworks.count >= 20)
      flash[:error] = "Usted ya tiene 20 o mas tareas"
      redirect_to home_path
    else
      @homework = Homework.new(params[:homework])
      @homework.user_id = userid
      respond_to do |format|
          if @homework.save
            format.html { redirect_to @homework, notice: 'Homework was successfully created.' }
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
	end
    @homework = Homework.find(params[:id])

    respond_to do |format|
      if @homework.update_attributes(params[:homework])
        format.html { redirect_to @homework, notice: 'Homework was successfully updated.' }
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
	end
    @homework = Homework.find(params[:id])
    #Antes de borrar eliminamos todo lo asociado
    participations = Participation.find_all_by_homework_id(params[:id])
    participation.each do |p|
      #Borrar achivos subidos
      p.destroy
    end
    
    @homework.destroy

    respond_to do |format|
      format.html { redirect_to homeworks_url }
      format.json { head :no_content }
    end
  end

  #Invite people to this homework
  def invite
    if(!Homework.exists?(:id=>params[:id]))
      flash[:error] = "Tarea inexistente"
      redirect_to home_path
      return
    end
    @homework = Homework.find(params[:id])
    render "invite.html.erb"
  end

  def saveinvites
    if(!Homework.exists?(:id=>params[:id]))
      flash[:error] = "Tarea inexistente"
      redirect_to home_path
      return
    end

    if(params[:invitados].nil? || params[:invitados].empty?)

    else
      counter = 0
      existed = false
      @homework = Homework.find(params[:id])
      params[:invitados].split(';').each do |g|
          if(!User.exists?(:email => g.delete(' '), :deleted => 0))
            @user = User.new
            @user.email = g.delete(' ')
            @user.name = "Firstname"
            @user.lastname = "Lastname"
            @user.admin = false

            #Guardamos el hash
            @user.salt = SecureRandom.hex
            @hashed = @user.salt
            100.times do
              @hashed = Digest::SHA1.hexdigest(@hashed)
            end
            @user.hashed_password = @hashed

            #Seteamos los valores por defecto
            @user.session_token = ""
            @user.last_login_date = Time.new.advance(:hours => -4)
            @user.last_login_server = "desaweb1.ing.puc.cl"

            @user.deleted = 0
            @user.save
            
            @hu = Participation.new
            @hu.user_id = @user.id
            @hu.homework_id = @homework.id
            @hu.save
            
            #begin
             # UserMailer.first_invitation_email(@homework, @user).deliver
            #rescue
            #end
          else
            #Revisar que no haya sido invitado
            @user = User.find_by_email_and_deleted(g.delete(' '), 0)
            if(!Participation.exists?(:user_id => @user.id))
               @hu = Participation.new
                @hu.user_id = @user.id
                @hu.homework_id = @homework.id
                @hu.save
                #begin
                 # UserMailer.invitation_email(@homework, @user).deliver
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
            message += " (El usuario ya fue invitado, por lo que fue omitido)"
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


end
