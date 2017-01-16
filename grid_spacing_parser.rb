#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'


def read_file(file_name)

	f = File.open("#{file_name}", "r")
	@doc = Nokogiri::XML(f)
	f.close

end

def find_gladefiles()

@glade_file_paths = Dir["./**/*.glade"]

end

# Sucht alle Grids und setzt die Abstaende
def search_grids(file_name)

	write_this_file_new = FALSE
	@doc.xpath('//object[@class = "GtkGrid"]').each do |g|

		if (g.parent.to_s !~ /row_spacing/)
			write_this_file_new = TRUE

			g.child.add_next_sibling("<property name=\"row_spacing\">2</property>\n")
		end
		if (g.parent.to_s !~ /column_spacing/)
			write_this_file_new = TRUE

			g.child.add_next_sibling("<property name=\"column_spacing\">5</property>\n")
		end

	end
	if(write_this_file_new)
		printf("%s\n", file_name)
		write_new_file(file_name)
		rename_file(file_name)
	end
end

def write_new_file(file_name)

f = File.open("#{file_name}.tmp", "w+")
	f.puts @doc.to_xml
f.close

end

def rename_file(file_name)

	File.rename("#{file_name}.tmp", "#{file_name}")

end	

def main()

	find_gladefiles()
	@glade_file_paths.each do |g|
		read_file(g)
		search_grids(g)
	end
	
end

main()
