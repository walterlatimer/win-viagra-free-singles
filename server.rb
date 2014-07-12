require 'sinatra'
require './parsed.rb'

class WinViagraFreeSingles < Sinatra::Base

	get '/' do
		erb :index
	end

	post '/' do
		if params[:file]
			@email = ParsedEmail.new(params[:file][:tempfile])
			message = "Text files only!  And please make sure they're actual emails, or else you'll break my poor app"
			params[:file][:type] == "text/plain" ? (erb :parsed) : message
		else
			erb :index
		end
	end

end