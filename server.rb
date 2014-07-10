require 'sinatra'

class WinViagraFreeSingles < Sinatra::Base
	get '/' do
		erb :index
	end

	post '/' do
		erb :parsed
	end
end