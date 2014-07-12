class ParsedEmail
	attr_reader :headers,
	            :body
	
	def initialize path
		parse(path)
	end

	# Update these guys
	def date() self.headers["Date"] end

	# Method calls for sanity in views
	def subject() self.headers["Subject"] || "[NO SUBJECT]" end
	def content_type() self.headers["Content-Type"].split(";").first rescue nil end
	def mime_version() self.headers["MIME-Version"] rescue nil end

	# Method calls listing email addresses as comma separated string
	def from() readable_emails("From") end
	def to() readable_emails("To") end
	def cc() readable_emails("Cc") end
	def bcc() readable_emails("Bcc") end
	def delivered_to() readable_emails("Delivered-To") end
	def return_path() readable_emails("Return-Path") end

	# Should always return an array, so make it an array if it's a string or nil
	def received()
		received = self.headers["Received"]
		received.class == Array ? received : [received]
	end

	# Returns nil if message_id is empty string
	def message_id
		message_id = self.headers["Message-ID"]
		message_id.nil? || message_id.empty? ? message_id : nil
	end

	def real_sender()
		self.received.last
	end

	# Returns an array of email addresses found in a given field and removes duplicates
	def addresses_in field
		self.headers[field].scan(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/).flatten.uniq rescue nil
	end

	# Returns a string of email addresses, comma separated
	def readable_emails header
		addresses_in(header).join(", ") rescue nil
	end

	private


	# Returns hash of headers and hash of body
	def parse path
		# Two newlines marks end of headers
		headers, body = path.read.split("\n\n", 2)
		@headers = parse_headers(headers)
		body = parse_body(self.content_type, body)
		body.class == Array ? @body = body : @body = [body]
	end


	#### PARSE HEADERS ####


	# Returns hash of headers
	def parse_headers raw_headers
		headers_array = remove_fws(raw_headers)
		create_headers_hash(headers_array)
	end

	# Removes FWS from headers
	def remove_fws headers_with_fws
		headers = []

		# Ignore line if it's just whitespace,
		# Add line to the last header if it begins with whitespace,
		# Otherwise, make it a new header
		headers_with_fws.each_line do |line|
			next if line =~ /^\s+$/
			next if line =~ /^((?!:)[\s\S])*$/ && headers.size == 0
			line =~ /^\s/ ? headers[-1] += line.strip : headers << line.strip
		end

		headers
	end

	# Returns hash of headers, with an array of values if there are multiple occurances of a key
	def create_headers_hash headers_array
		headers = {}

		# Store values as hash, but don't include duplicate values
		headers_array.map do |line|
			key, value = line.split(": ", 2)
			headers[key] ||= []
			headers[key] << value unless headers[key].include? value
		end

		# Pop value from array if there's only one value
		headers.each do |key, value|
			headers[key] = value.pop if value.length == 1
		end
		headers
	end


	#### PARSE BODY ####


	# Returns hash of body, with types as keys
	# No it doesn't
	def parse_body content_type, body
		case content_type
		when "multipart/alternative" then parse_multipart(body)
		when "text/plain" then parse_text_plain(body)
		when "text/html" then parse_text_html(body)
		when nil then "[No Content]"
		else content_type + " not yet supported"
		end
	end


	# Returns an array of each version of the body
	def parse_multipart raw_body
		boundary = get_boundary(@headers["Content-Type"])

		bodies = []
		# Split the body at the boundary, then parse each individually
		split_multipart(boundary, raw_body).each do |each_body|
			# Get the content type of each version of the body
			body_content_type = each_body.split("Content-Type: ", 2).last.split(";", 2).first
			# Get body
			this_body = each_body.split(/\n/, 2).last
			# Parse it again, henny
			bodies << parse_body(body_content_type, this_body).split(/\n\n/, 2).last
		end
		bodies
	end

	def parse_text_plain raw_body
		'<pre>' + raw_body.gsub(/(?:\n\r?|\r\n?)|=0D/, '<br>').gsub("="," ") + '</pre>'
	end

	def parse_text_html raw_body
		raw_body.gsub("=C2=A0"," ").gsub(/(?:\n\r?|\r\n?)|=/,"").gsub("C2A0"," ").gsub("\t", "&nbsp;&nbsp;&nbsp;&nbsp;")
	end

	# Pulls the boundary out of the content-type header
	def get_boundary content_type_header
		comments = content_type_header.split(";", 2).last
		boundary = "--" + comments.match(/boundary=(.+)[;]|boundary=(.+)[\w]/).to_s.gsub(/(boundary=)|(")/, "")
	end

	# Returns an array of an array of each version of the body
	def split_multipart(bound, multipart_body)
		multipart_body.split(bound + "\n").reject! { |c| c.empty? }
	end

end