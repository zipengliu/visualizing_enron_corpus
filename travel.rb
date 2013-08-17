
module Travel 

def travel(dir, depth, max_depth = 0)
	if !File.directory?(dir) then
		return
	end
	Dir.foreach(dir) do |f|
		if !(f =~ /^\./) then
			filename = File.join(dir, f)
			if File.directory?(filename) and (depth + 1 < max_depth or max_depth == 0) then
				travel(filename, depth + 1, max_depth) {|d| yield d}
			else
				yield filename
			end
		end
	end
end

end
