class ParsedEmail
	attr_reader :headers,
	            :body
	
	def initialize raw_email
		@headers, @body = parse(raw_email)
	end


	# Method calls for sanity in views
	def subject() self.headers["Subject"] end
	def content_type() self.headers["Content-Type"] end


	# Method calls listing email addresses as comma separated string
	def from() addresses_in("From").join(", ") end
	def to() addresses_in("To").join(", ") end
	def cc() addresses_in("Cc").join(", ") end
	def bcc() addresses_in("Bcc").join(", ") end


	# Returns an array of email addresses found in a given field and removes duplicates
	def addresses_in field
		self.headers[field].scan(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/).flatten.uniq rescue []
	end





	private

	# Returns hash of headers and hash of body
	def parse email
		# Two newlines marks end of headers
		split = email.read.split("\n\n", 2)

		headers = parse_headers(split[0])
		body = split[1]

		[headers, body]
	end


	def parse_headers raw_headers
		headers_array = remove_fws(raw_headers)
		create_headers_hash(headers_array)
	end


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


	def create_headers_hash headers_array
		headers = {}

		# Store values as hash, but don't include duplicate values
		headers_array.map do |line|
			header = line.split(": ", 2)
			headers[header[0]] ||= []
			headers[header[0]] << header[1] unless headers[header[0]].include? header[1]
		end

		# Pop value from array if there's only one value
		headers.each do |key, value|
			headers[key] = value.pop if value.length == 1
		end

		headers
	end

end