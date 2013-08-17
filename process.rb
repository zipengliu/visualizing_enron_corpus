#!/usr/bin/env ruby
# encoding: utf-8

module ExtractMail

require "Date"
require "iconv"
$converter = Iconv.new("UTF-8", "latin1")

def process_mail(filename)
	#puts filename

	email = {}
	if File.file?(filename) then
		File.open(filename, "r") do |mail_file|
			#puts "Processing #{filename}"
			line = mail_file.gets
			while (line && !line.empty? && line != "\n")
				#line = line.gsub("\n", "")
				line = $converter.iconv(line)
				if email[:From].nil? && /^From:\s/ =~ line then
					email[:From] = line.sub(/From:\s/, "").gsub(/\s/, "")
					line = mail_file.gets
				else	
					if email[:To].nil? && /^To:\s/ =~ line then
						email[:To] = line.sub(/To:\s/, "")
						while (line = mail_file.gets)
							#line = line.gsub(/\n/, "")
							line = $converter.iconv(line)
							if !(line =~ /^\s/) then
								break
							end
							email[:To].concat(line)
						end
						email[:To] = email[:To].scan(/\S+@\S+\.\S+/)
						email[:To].map! {|s| s.delete("<>,")}
					else
						if email[:Cc].nil? && /^Cc:\s/ =~ line then
							email[:Cc] = line.sub(/Cc:\s/, "")
							#while (line = mail_file.gets && line =~ /^\s/)
							while (line = mail_file.gets)
								line = $converter.iconv(line)
								if !(line =~ /^\s/) then
									break
								end
								email[:Cc].concat(line)
							end
							email[:Cc] = email[:Cc].scan(/\S+@\S+\.\S+/)
							email[:Cc].map! {|s| s.delete("<>,")}
						else
							if email[:Date].nil? && line =~ /^Date:\s/ then
								# deal with "year 0001"
								email[:Date] = line.sub(/^Date:\s/, "").delete("\r\n")
								email[:Date].sub!(/000([0-9])/, "200\\1")
							end
							line = mail_file.gets
						end
					end
				end
			end
			if email[:Cc].nil? then
				email[:Cc] = []
			end
			if email[:To].nil? then
				email[:To] = []
			end
		end
	end

	email
end

def pick(s)
	m = /[\w\.\-]*@[\w\.\-]*/.match(s)
	if m.nil? then
		nil
	else
		m[0]
	end
end

def standardize(data)
	# standardize the format of the email address
	for mail in data
		mail[:From] = pick(mail[:From])
		mail[:To].each_index do |i|
			mail[:To][i] = pick(mail[:To][i])
			if mail[:To][i].nil? then
				mail[:To] = []
				break
			end
		end
		mail[:Cc].each_index do |i|
			mail[:Cc][i] = pick(mail[:Cc][i])
			if mail[:Cc[i]].nil? then
				mail[:Cc] = []
				break
			end
		end
	end

	data
end

end

