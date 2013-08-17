#!/usr/bin/env ruby
# encoding: utf-8

def dump(file, data)
	# dump it in json
	require "json"

	json = JSON.pretty_generate(data)
	#puts json

	File.open(file, "w") do |oufile|
		oufile.write(json)
	end
end

require "./process.rb"
include ExtractMail

mails_path = "./enron_mail_20110402/maildir/allen-p"
i = 0
j = 0
threads = []
results = []

require "./travel.rb"
include Travel
Travel.travel(mails_path, 0, 1) do |d|
	threads[i] = Thread.new() do
		Travel.travel(d, 0, 0) do |f| 
			if results[j].nil? then
				results[j] = Array.new()
			end
			results[j].push(*ExtractMail.process_mail(f))
		end
	end
	i += 1
	if !results[j].nil? then
		j += 1
	end
end

puts "#{threads.length}"
threads.each() {|t| t.join()}

data = results.reduce(:concat)

puts "The number of emails: #{data.length}"

dump("mail0.json", data)
puts "Done"
