#!/usr/bin/env ruby

require "json"
require "./travel.rb"
include Travel

def load_json_file(path)
	File.open(path) {|f| JSON.load(f)}
end

def compare_email(a, b)
	#a comparison between a and b, and return -1, when a follows b, 0 when a and b are equivalent, or +1 if b follows a.
	require "Date"
	da = DateTime.parse(a["Date"])
	db = DateTime.parse(b["Date"])
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

def standardize_date(date) 
	date
end

def search_name(a, x)
	p = a.index(x)
	if p.nil? and x.include?(" ") then
		tmp = x.split(" ")
		if x.length == 2 then
			a.each_index do |i|
				if a[i].include?(tmp[0]) and a[i].include?(tmp[1]) then
					return i
				end
			end
		end
	end
	p
end

def filter(data, filter_list)
	filtered = []
	data.each do |mail|
		mail_filtered = {}
		mail_filtered["XFrom"] = search_name(filter_list, mail["XFrom"])
		mail_filtered["Date"] = standardize_date(mail["Date"])
		if mail["XTo"].nil? then
			mail_filtered["XTo"] = nil
		else
			tmp  = mail["XTo"].map {|add| search_name(filter_list, add)}
			mail_filtered["XTo"] = tmp.reject {|x| x.nil?}
		end
		if mail["XCc"].nil? then
			mail_filtered["XCc"] = nil
		else
			tmp  = mail["XCc"].map {|add| search_name(filter_list, add)}
			mail_filtered["XCc"] = tmp.reject {|x| x.nil?}
		end
		filtered.push(mail_filtered)
	end
	filtered.sort{|a, b| compare_email(a, b)}
end

def dump(file, data, pretty = true)
	# dump it in json
	require "json"

	if pretty then
		json = JSON.pretty_generate(data)
	else
		json = JSON.generate(data)
	end
	#puts json

	File.open(file, "w") do |oufile|
		oufile.write(json)
	end
end

json_file = "./enron_not_sorted.json"
data = load_json_file(json_file)

data_filtered = {}
threads = []
i = 0
filter_list = data.keys

data.each_key do |name|
	threads[i] = Thread.new() do
		id = search_name(filter_list, name)
		data_filtered[id] = {}
		data[name].each_key do |key|
			data_filtered[id][key] = filter(data[name][key], filter_list)
		end
		puts name
	end
	i += 1
end

name_mapping = Hash[filter_list.map.with_index {|x, i| [i, x]}]
dump("name_mapping.json", name_mapping)
threads.each() {|t| t.join()}

dump("enron_filtered_sorted.json", data_filtered)

puts "Done"
