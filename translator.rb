#!/usr/bin/env ruby
#
# Dieses Skript durchsucht alle Glade-Files 
# nach übersetzbaren Texten und 
# falls diese nicht im KK translate vorkommen,
# werden diese in ein Textfile geschrieben.
#
# produced by Elias Häfliger

require 'find'

out_file_name = "out.txt"
kk_file_name = "translat.txt"

def is_number? string
	true if Float(string) rescue false
end

# suche nach allen Glade-Files in src/
glade_file_paths = []
Find.find('./') do |path|
	glade_file_paths << path if path =~ /.*\.glade$/
end

written = []
exist = []

# liest alle bereits vorhandenen Karteikaste-Übersetzungen ein
File.open( kk_file_name, "r" ).each do |kk_line|
	exist << kk_line.split.first
end

# erstelle neues File für Ausgabe aller noch nicht existierenden Texten
File.open( out_file_name, "w" ) do |out_file|

	# durchlaufe jedes Glade-File und gib jede Zeile aus.
	glade_file_paths.each do |path|
		File.open( path, "r" ).each do |line|
			line = line[/>(.*?)</m,1]

			# schreibe in out_file, wenn noch nicht vorhanden.
			if ( line and line.length > 2 and not is_number?(line) and not written.include?( line ) and not exist.include?( line ))
				written << line
				puts line
				out_file.puts( line )
			end
		end
	end
end