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
		message_id.empty? ? message_id : nil
	end

	def real_sender()
		self.received.last
	end

	# Returns an array of email addresses found in a given field and removes duplicates
	def addresses_in field
		self.headers[field].scan(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/).flatten.uniq rescue nil
	end


	private


	# Returns hash of headers and hash of body
	def parse path
		# Two newlines marks end of headers
		headers, body = path.read.split("\n\n", 2)
		@headers = parse_headers(headers)
		@body = parse_body(self.content_type, body)
	end

	# Returns hash of headers
	def parse_headers raw_headers
		headers_array = remove_fws(raw_headers)
		create_headers_hash(headers_array)
	end

	# Returns hash of body, with types as keys
	def parse_body content_type, raw_body
		if content_type == "multipart/alternative"
			"Multiplart!!!"
		else
			"Not multipart"
		end
	end

	# Removes FWS from headers
	def remove_fws headers_with_fws
		headers = []

		# Ignore line if it's just whitespace,
		# Add line to the last header if it begins with whitespace,
		# Otherwise, make it a new header
		headers_with_fws.each_line do |line|
			next if line =~ /^\s+$/
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

	# Returns a string of email addresses, comma separated
	def readable_emails header
		addresses_in(readable).join(", ") rescue nil
	end

end