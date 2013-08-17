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

beginning_time = Time.now


mails_path = "./enron_mail_20110402/maildir"
#mails_path = "./test"
i = 0
j = 0
threads = []
results = []

require "./travel.rb"
include Travel
Travel.travel(mails_path, 0, 1) do |person_maildir|
	person = File.basename(person_maildir)
	threads[i] = Thread.new() do
		sent = []
		recv = []
		Travel.travel(person_maildir, 0, 1) do |subdir| 
			if /sent/ =~ subdir then
				# The mail he sent
				Travel.travel(subdir, 0, 0) do |f|
					mail = ExtractMail.process_mail(f)
					mail.delete(:From)
					sent.push(mail)
				end
			else 
				if !(/delete/ =~ subdir) then
					# The mail he received
					Travel.travel(subdir, 0, 0) do |f|
						mail = ExtractMail.process_mail(f)
						mail.delete(:To)
						mail.delete(:Cc)
						recv.push(mail)
					end
				end
			end
		end
		dump(File.join("enron_corpus", person, "sent.json"), sent.sort{|a, b| compare_email(a, b)})
		dump(File.join("enron_corpus", person, "recv.json"), recv.sort{|a, b| compare_email(a, b)})
		puts "#{person}   \tSent: #{sent.length}\tRecv: #{recv.length}"
	end
	i += 1
end

threads.each() {|t| t.join()}

end_time = Time.now
puts "Time elapsed #{(end_time - beginning_time)} seconds"

puts "Done"
