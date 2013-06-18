require 'rubygems'
require 'zip/zip'
require 'tempfile'

class FileController < ApplicationController
	def enunciado
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		homework = Homework.find(params[:homework_id])
		
		if(homework.user.id != session[:user_id] and !Participation.exists?(:user_id => session[:user_id], :homework_id => homework.id))
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		File.open(Rails.root.join('shared_files', "#{homework.user.id.to_s}/#{homework.id.to_s}", homework.filename), 'rb') do |file|
			return send_data(file.read)
		end
	end
	
	def single_file
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		homework = Homework.find(params[:homework_id])
		
		if(homework.user.id != session[:user_id] and !Participation.exists?(:user_id => session[:user_id], :homework_id => homework.id))
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		if(homework.user.id != session[:user_id] and params[:user_id].to_i != session[:user_id].to_i)
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		participation = Participation.find_by_user_id_and_homework_id(params[:user_id], homework.id)
		
		archive = participation.archives.find(params[:file])
		
		File.open(Rails.root.join('shared_files', "#{homework.user.id.to_s}/#{homework.id.to_s}/#{participation.user_id.to_s}/#{archive.version.to_s}", archive.name), 'rb') do |file|
			return send_data(file.read, :filename => archive.name)
		end
		
	end
	
	def version_file
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		homework = Homework.find(params[:homework_id])
		
		if(homework.user.id != session[:user_id] and !Participation.exists?(:user_id => session[:user_id], :homework_id => homework.id))
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		if(homework.user.id != session[:user_id] and params[:user_id].to_i != session[:user_id].to_i)
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		participation = Participation.find_by_user_id_and_homework_id(params[:user_id], homework.id)
		
		file_path = Dir::pwd + "/shared_files/#{homework.user_id.to_s}/#{homework.id.to_s}/#{participation.user_id.to_s}/#{params[:version].to_s}"
		zipfile_name = Dir::pwd + "/shared_files/#{homework.user_id.to_s}/#{homework.id.to_s}/#{participation.user_id.to_s}/#{params[:version].to_s}.zip"
		
		if(!File.exists?(zipfile_name))
			participation.archives.find_all_by_version(params[:version].to_i).each do |a|
				Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
					zipfile.add(a.name, file_path + '/' + a.name)
				end
			end
		end
		
		File.open(zipfile_name, 'rb') do |file|
			return send_data(file.read, :filename => "#{participation.user.lastname}_#{participation.user.name}_version_#{params[:version]}.zip")
		end
		
	end
	
	def latest
		if(!session[:user_id])
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		homework = Homework.find(params[:homework_id])
		
		if(session[:user_id] != homework.user.id)
			flash[:error] = "Acceso denegado"
			return redirect_to home_path
		end
		
		zipfile_name = Dir::pwd + "/shared_files/#{homework.user_id.to_s}/#{homework.id.to_s}/#{homework.name}_#{DateTime.now.to_s}.zip"
		
		homework.participations.each do |p|
			if(p.archives.count > 0)
				version = 1
				p.archives.each do |a|
					if(a.version > version)
						version = a.version
					end
				end
				version_zipfile_name = Dir::pwd + "/shared_files/#{homework.user_id.to_s}/#{homework.id.to_s}/#{p.user_id.to_s}/#{version.to_s}.zip"
				if(File.exists?(version_zipfile_name))
					Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
						zipfile.add("#{p.lastname}_#{p.name}_#{p.id}_version_#{version}.zip", version_zipfile_name)
					end
				else
				end
			end
		end
		
	end
	
end