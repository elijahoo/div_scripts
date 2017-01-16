#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

TEXTS = { "gtk-find" => "Suchen", "gtk-cancel" => "Abbrechen", "gtk-refresh" => "Aktualisieren", "gtk-apply" => "Übernehmen", "gtk-save" => "Speichern", "gtk-floppy" => "Speichern", "gtk-print" => "Drucken", "gtk-copy" => "Kopieren", "gtk-paste" => "Einfügen", "gtk-preferences" => "Einstellungen", "gtk-remove" => "Löschen", "gtk-add" => "Anlegen", "gtk-open" => "Öffnen", "gtk-close" => "Schliessen", "gtk-revert-to-saved" => "Verwerfen"}

def read_file(file_name)

  f = File.open("#{file_name}", "r")
  @doc = Nokogiri::XML(f)
  f.close

end

def find_gladefiles()

  @glade_file_paths = Dir["./**/*.glade"]

end

# Sucht zu den Buttons den Stock-Item Text
def search_stockitem(button_name)

  @doc.xpath("//object[@id = \"#{button_name}\"]").each do |i|

    stock_item = i.xpath('./property [@name="stock"]/text()')

    return stock_item 
  end
end

# Sucht alle Buttons mit Bild und noch keiner Beschriftung
def search_buttons(file_name)

  @doc.xpath('//object[@class = "GtkButton"]/property[@name = "image"]').each do |b|

    if (b.parent.to_s !~ /tooltip_text/)
      @button = b.parent.xpath('./property [@name="image"]/text()')

      button_item = search_stockitem(@button)

      b.add_next_sibling("\n<property name=\"tooltip_text\" translatable=\"yes\">#{TEXTS["#{button_item}"]}</property>")
    end
  end
  if (@button)
    printf("%s\n", file_name)
    write_new_file(file_name)
    rename_file(file_name)
  end
  @button = FALSE

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
    search_buttons(g)
  end
	
end

main()
