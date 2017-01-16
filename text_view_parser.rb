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

# Sucht alle TextView und setzt den Abstand links auf 5
def search_textViews(file_name)

	write_this_file_new = FALSE
	@doc.xpath('//object[@class = "GtkTextView"]').each do |t|

		if (t.parent.to_s !~ /left_margin/)
			write_this_file_new = TRUE

			t.child.add_next_sibling("<property name=\"left_margin\">5</property>\n")
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
		search_textViews(g)
	end
	
end

main()
