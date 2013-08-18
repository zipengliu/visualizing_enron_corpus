#!/usr/bin/env ruby
# encoding: utf-8

require "./process.rb"
include ExtractMail

require "./travel.rb"
include Travel

def dump(file, data)
	# dump it in json
	require "json"

	dirname = File.dirname(file)
	if !File.directory?(dirname) then
		Dir.mkdir(dirname)
	end

	json = JSON.pretty_generate(data)
	#puts json

	File.open(file, "w") do |oufile|
		oufile.write(json)
	end
end

def compare_email(a, b)
	#a comparison between a and b, and return -1, when a follows b, 0 when a and b are equivalent, or +1 if b follows a.
	require "Date"
	da = DateTime.parse(a[:Date])
	db = DateTime.parse(b[:Date])
	if da < db then
		1
	else
		if da > db then
			-1
		else
			0
		end
	end
end

def guess(first, last, add)
	if !add.include?("enron.com") or !add.include?(last) then
		return false
	end
	fields = add.split("@")[0].scan(/\w*/)
	fields.delete(last)
	fields.each do |f|
		if f[0] == first then
			return true
		end
	end
	false
end

def add_address(person, address, mail, mode)
	first_name = person.split("-")[1]
	last_name = person.split("-")[0]
	if mode == 0 then		# processing sent mail
		# Check the "From" 
		if guess(first_name, last_name, mail[:From]) and !address.include?(mail[:From]) then
			address.push(mail[:From])
		end
	else					# processing recv mail
		# Check the "To"
		mail[:To].each do |a|
			if guess(first_name, last_name, a) and !address.include?(a) then
				address.push(a)
			end
		end
	end
	# Check the "Cc"
	mail[:Cc].each do |a|
		if guess(first_name, last_name, a) and !address.include?(a) then
			address.push(a)
		end
	end
	address
end

beginning_time = Time.now


#mails_path = "./enron_mail_20110402/maildir"
mails_path = "./test"
i = 0
j = 0
threads = []
results = []

data = {}
address = {}

require "./travel.rb"
include Travel
Travel.travel(mails_path, 0, 1) do |person_maildir|
	person = File.basename(person_maildir)
	threads[i] = Thread.new() do
		sent = []
		recv = []
		address[person] = []
		Travel.travel(person_maildir, 0, 1) do |subdir| 
			if /sent/ =~ subdir then
				# The mail he sent
				Travel.travel(subdir, 0, 0) do |f|
					mail = ExtractMail.process_mail(f)
					address[person] = add_address(person, address[person], mail, 0)
					mail.delete(:From)
					sent.push(mail)
				end
			else 
				if /delete/ !~ subdir then
					# The mail he received
					Travel.travel(subdir, 0, 0) do |f|
						mail = ExtractMail.process_mail(f)
						address[person] = add_address(person, address[person], mail, 1)
						mail.delete(:To)
						mail.delete(:Cc)
						recv.push(mail)
					end
				end
			end
		end
		#dump(File.join("enron_corpus", person, "sent.json"), sent.sort{|a, b| compare_email(a, b)})
		#dump(File.join("enron_corpus", person, "recv.json"), recv.sort{|a, b| compare_email(a, b)})
		
		data[person] = {}
		data[person][:sent] = sent
		data[person][:recv] = recv
		puts "#{person}   \tSent: #{sent.length}\tRecv: #{recv.length}"
	end
	i += 1
end

threads.each() {|t| t.join()}

dump("enron.json", data)
puts address
dump("addresses.json", address)

end_time = Time.now
puts "Time elapsed #{(end_time - beginning_time)} seconds"

puts "Done"
