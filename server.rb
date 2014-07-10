require 'sinatra'

class WinViagraFreeSingles < Sinatra::Base

	get '/' do
		erb :index
	end

	post '/' do
		@email = ParsedEmail.new(params[:file][:tempfile])
		erb :parsed
	end

end

class ParsedEmail
	attr_reader :headers,
	            :body
	
	def initialize(raw_email)
		raw_headers, raw_body = split_headers_and_body(raw_email)
		@headers = create_array_of_headers(raw_headers)
	end

	private

	def split_headers_and_body(raw_email)
		raw_email.read.split("\n\n", 2)
	end

	def create_array_of_headers(raw_headers)
		headers = []
		raw_headers.each_line do |line|

			next if line =~ /^\s+$/ # Skip line if it's just whitespace
			line.rstrip!

			# Add line to the last element if it begins with whitespace,
			# Otherwise, make it a new element
			line =~ /^\s/ ? headers[-1] += line : headers << line
		end
		headers
	end
end