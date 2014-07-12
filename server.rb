require 'sinatra'
require './parsed.rb'

class WinViagraFreeSingles < Sinatra::Base

	get '/' do
		erb :index
	end

	post '/' do
		if params[:file]
			@email = ParsedEmail.new(params[:file][:tempfile])
			type = params[:file][:type] == "text/plain"
			type ? (erb :parsed) : "Text files only!"
		else
			erb :index
		end
	end

end