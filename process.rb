#!/usr/bin/env ruby
# encoding: utf-8

module ExtractMail

require "Date"
require "iconv"
require "test/unit"
include Test::Unit::Assertions
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

# extract a list of full names out of a string
def extract_full_names(s)
	s = " ".concat(s).concat(" ")
	#puts "###############################################"
	#puts s
	list = s.scan(/\s'?"?\w+,?\s\w+[,']?\.?\s?\w*\s?&?\s?\w*"?'?\s/)
	#puts "=>", list
	list.map! do |name| 
		tmp = name.sub(/^\s*/, "").sub(/\s*$/, "").sub(/<.+>/, "").sub(/,$/, "").delete("\"\'\.")
		if tmp.include?(",") and !tmp.include?("&")then
			l = tmp.split(",")
			l[1].sub!(/^\s*/, "")
			#assert(l.length == 2, "fails at #{tmp} out of #{s}")
			if (l.length != 2) then
				tmp = ""
			else
				tmp = l[1].concat(" ").concat(l[0])
			end
		end
		tmp
	end
	list
end

def process_mail_xfields(filename)
	email = {}
	File.open(filename, "r") do |file|
		while (line = $converter.iconv(file.gets) and /^\S/ =~ line)
			if /^X-From:\s/i =~ line then
				tmp = line.sub(/^X-From:\s/, "").delete("\r\n")			
				tmp2 = extract_full_names(tmp)
				if !tmp2.empty? then
					email[:XFrom] = tmp2[0]
				else
					email[:XFrom] = []
				end
			else
				if /^Date:\s/ =~ line then
					email[:Date] = line.sub(/^Date:\s/, "").delete("\r\n")
				else
					if /^X-To:\s/ =~ line or /^X-Cc:\s/i =~ line then
						#tmp = line.sub(/^X-\w*:\s/, "").delete("\r\n")			
						tmp = line
						while (line = $converter.iconv(file.gets) and /^\s/ =~ line)
							tmp += line
						end
						if /^X-To:\s/i =~ tmp then
							tmp.sub!(/^X-To:\s/, "").delete("\r\n")			
							email[:XTo] = extract_full_names(tmp)
						else
							tmp.sub!(/^X-Cc:\s/, "").delete("\r\n")			
							email[:XCc] = extract_full_names(tmp)
						end
					end
				end
			end
		end
	end
	if !email.has_key?(:XFrom) then
		email[:XFrom] = []
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

