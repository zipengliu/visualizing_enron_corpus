#!/usr/bin/env ruby
# encoding: utf-8

require "./travel.rb"
include Travel

def get_from_address(filename)
	File.open(filename) do |f|
		while (line = f.gets and /^\S/ =~ line)
			if /^From:\s/ =~ line then
				return line.gsub(/^From:\s/, "").delete("\n\r")
			end
		end
	end
end

def get_add(path)
	list = []
	Travel.travel(path, 0, 1) do |person|
		has_sent = false
		Travel.travel(person, 0, 1) do |dir|
			if /sent/ =~ dir then			# select the sent mail directory to get his address
				Travel.travel(dir, 0, 1) do |f|
					list.push(get_from_address(f))
					has_sent = true
					break
				end
				break
			end
		end
		if !has_sent then
			#puts person.concat(" has no sent mails!")
		end
	end
	# add one address manually
	list.push("steven.harris@enron.com")
end

def load_json_file(path)
	File.open(path) {|f| JSON.load(f)}
end

def filter(data, filter_list)
	data_filtered = []
	data.each do |mail|
		mail_filtered = {}
		mail_filtered["From"] = (filter_list.include?(mail["From"]))? mail["From"] : nil
		mail_filtered["Date"] = mail["Date"]
		if mail["To"].nil? then
			mail_filtered["To"] = nil
		else
			mail_filtered["To"] = mail["To"].select {|add| filter_list.include?(add)}
		end
		if mail["Cc"].nil? then
			mail_filtered["Cc"] = nil
		else
			mail_filtered["Cc"] = mail["Cc"].select {|add| filter_list.include?(add)}
		end
		data_filtered.push(mail_filtered)
	end
	data_filtered
end

def dump(file, data)
	# dump it in json
	require "json"

	json = JSON.pretty_generate(data)
	#puts json

	File.open(file, "w") do |oufile|
		oufile.write(json)
	end
end

mail_path = "./enron_mail_20110402/maildir"
add_list = get_add(mail_path)
puts add_list.sort
puts add_list.length

require "json"
json_file = "./mail0.json"
data = load_json_file(json_file)

data = filter(data, add_list)

dump("mail_filtered.json", data)

puts "Done"
