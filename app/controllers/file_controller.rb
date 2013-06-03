require 'rubygems'
require 'zip'

class FileController < ApplicationController

	def filetest		
		folder = "Users/Jota/Desktop/stuff_to_zip"
		input_filenames = ['image.jpg', 'description.txt']

		zipfile_name = "/Users/Jota/Desktop/archive.zip"

		Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
		  input_filenames.each do |filename|
		    # Two arguments:
		    # - The name of the file as it will appear in the archive
		    # - The original file, including the path to find it
		    zipfile.add(filename, folder + '/' + filename)
		  end
		end
		flash[:succes] = "Archivo comprimido!"
		redirect_to home_path
	end
	
end