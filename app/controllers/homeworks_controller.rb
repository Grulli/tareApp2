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
    @homework.destroy

    respond_to do |format|
      format.html { redirect_to homeworks_url }
      format.json { head :no_content }
    end
  end
end
