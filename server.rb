require 'sinatra'
require './parsed.rb'

class WinViagraFreeSingles < Sinatra::Base

	get '/' do
		erb :index
	end

	post '/' do
		@email = ParsedEmail.new(params[:file][:tempfile])
		erb :parsed
	end

end