#!/usr/bin/env ruby
# encoding: utf-8

require "./travel.rb"
include Travel

def dump(file, data)
	# dump it in json
	require "json"

	json = JSON.pretty_generate(data)
	#puts json

	File.open(file, "w") do |oufile|
		oufile.write(json)
	end
end

list = []
Travel.travel("enron_corpus", 0, 1) do |person|
	list.push(File.basename(person))
end

dump("people_list.json", list)


