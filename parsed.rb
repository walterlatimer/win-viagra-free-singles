class ParsedEmail
	attr_reader :headers,
	            :body
	
	def initialize raw_email
		@headers, @body = parse raw_email
	end

	# Method calls for sanity in views
	def subject() self.headers["Subject"] end
	def content_type() self.headers["Content-Type"] end


	# Method calls listing email addresses as comma separated string
	def from() addresses_in("From").join(", ") end
	def to() addresses_in("To").join(", ") end
	def cc() addresses_in("Cc").join(", ") end
	def bcc() addresses_in("Bcc").join(", ") end

	private

	# Returns hash of headers and hash of body
	def parse email
		# Two newlines marks end of headers
		split = email.read.split("\n\n", 2)
		headers = parse_headers(split[0])
		body = split[1]
		return [headers, body]
	end


	def parse_headers headers
		headers_without_fws = remove_fws(headers)
		create_headers_hash(headers_without_fws)
	end


	# Skip line if it's just whitespace,
	# Add line to the last element if it begins with whitespace,
	# Otherwise, make it a new element
	def remove_fws raw_headers
		headers = []
		raw_headers.each_line do |line|
			next if line =~ /^\s+$/
			line =~ /^\s/ ? headers[-1] += line.strip : headers << line.strip
		end
		headers
	end

	# Convert headers into hash, preserving duplicates with an array
	def create_headers_hash array
		array.map{ |line| line.split(": ", 2) }.to_h
	end


	# Returns an array of email addresses found in a given field and removes duplicates
	def addresses_in field
		self.headers[field].scan(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/).flatten.uniq rescue []
	end

end