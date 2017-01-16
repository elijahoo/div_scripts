#!/usr/bin/ruby

require 'logger'
require 'fileutils'

require 'rubygems'     
require 'mini_magick'  # lib to capture image width/height
require 'kartei'       # kartei libs
require "/usr/lib/ruby/gems/1.8/gems/kartei-0.0.1-x86-linux/lib/kartei/models/lageplan.rb"

# init logger
$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

# set the default logger for Karteikasten
Kartei::Karteikasten.logger = logger

# C-Binding should convert kartei fields in 
# real ruby datatypes/objects (e.g. boolean, fixnum)
Kartei::Karteikasten.typesafe = false

# Karteikasten is LATIN-1. If you want to work in UTF-8,
# then set this to UTF-8. Be cautious when using strings
# from unknown sources (e.g. webservice, files) and know
# your encoding ...
#
# TODO: needs to be tested carefully!
#Kartei::Karteikasten.encoding = 'UTF-8'

MANDANT_IDENT = ARGV[0]
unless MANDANT_IDENT
  raise "usage: ruby navikart_transform.rb <MANDANT_IDENT> (<LAGEPLAN_IDENT>)"
end
MANDANT_DIR = "/sfmtool/prg/" + MANDANT_IDENT.gsub( /[^A-Za-z0-9]/, '')[0,8]
NAVIKART_NAME = ARGV[1]

$logger.debug "Mandant = #{MANDANT_IDENT.inspect}"
$logger.debug "Mandantverzeichnis = #{MANDANT_DIR.inspect}"
$logger.debug "Lageplan = #{NAVIKART_NAME.inspect}"

navikart_dat = "#{MANDANT_DIR}/navikart.dat"
if not File.exists? MANDANT_DIR
  raise "Mandant #{MANDANT_IDENT} existiert nicht (Verzeichnis #{MANDANT_DIR} nicht gefunden)."
elsif not File.exists? navikart_dat
  raise "Datei #{navikart_dat.inspect} existiert nicht."
end

Thread.current[:mandant] = MANDANT_IDENT

IMAGE_MAX_WIDTH = 1600
IMAGE_MAX_HEIGHT = 1200

grafik_resized_dir = "#{MANDANT_DIR}/grafik_resized/"
$logger.debug "Erstelle Verzeichnis #{grafik_resized_dir} falls nicht vorhanden."
FileUtils.mkdir_p(grafik_resized_dir)

class KarteiHash
  def initialize(hash = {}, record_number = nil)
    @hash = hash
    @record_number = record_number
  end

  def to_s
    output = []
    if @hash.size > 0
      nums = @hash.keys.sort {|a,b| a.to_i <=> b.to_i}
      nums.each do |num|
        output << sprintf("%3d %s",num.to_i,@hash[num])
      end
      output << "."
    else
      #raise "empty record => #{output_fields.inspect}"
    end
    output = output.join("\n")
    if @record_number
      output << " R #{@record_number}"
    end
    return output
  end

end

#Wird mit der Identifikation benötigt!
#NAVIKART_LABEL_WIDGETS = {
#  'W' => 'Wert mit Uebersetzung (fdspunkt.txtwert...)',
#  'B' => 'Balken ohne Wert (fdspunkt.minwert, fdspunkt.maxwert)',
#  'WB'=> 'Balken mit Wert (fdspunkt.minwert, fdspunkt.maxwert)',
#  'D' => 'Datum und Uhrzeit von Datenpunkt letzter Wert (fds/dat/punkdaten.dat)'
#}

NAVIKART_LABEL_WIDGETS = {
  'W' => '[W]',
  'B' => '[B]',
  'WB'=> '[WB]',
  'D' => '[D]'
}

#nks = []
#nk = Kartei::Navikart.find(0, 'Temp&Feuchte_STA_Seite1')

func = {}

File.open('lageplan.imp', 'w') do |output|

  name_von = NAVIKART_NAME || ''
  name_bis = NAVIKART_NAME || 'ZZZ'

  Kartei::Navikart.search_by_tree(:baum => 0, :von => {:name => name_von}, :bis => {:name => name_bis}).each do |nk, record, begriff|

    ## parse navikart and create record for new navikart
    $logger.debug "NAVIKART: parse #{nk.name.inspect}"
    #  find out extension of navikart

    extension = ''
    gtk_record = "#{record}"
    gtk_record[0] ='G'

    gtk_file_pattern = grafik_resized_dir + "NK#{gtk_record}.*"

    # use already resized images
    gtk_background = Dir[grafik_resized_dir + "NK#{gtk_record}.*"]
    if gtk_background.empty?
      file_pattern = "#{MANDANT_DIR}/grafik/NK#{record}.*"
      background = Dir[file_pattern]
    else
      $logger.debug "NAVIKART: skip #{gtk_background.inspect}. File already exists"
      file_pattern = "#{MANDANT_DIR}/grafik/NK#{gtk_record}.*"
      background = Dir[file_pattern]
    end
     
    if background.empty?
      $logger.warn "NAVIKART: no image found for pattern #{file_pattern.inspect}"
      $logger.warn "NAVIKART: background is  #{background}"
    elsif background.size == 1
      extension = background.first.split('.').last
    else
      extensions = background.map{|b| b.split('.').last.downcase }.sort
      $logger.debug "NAVIKART: multiple extensions for navikart found #{extensions.inspect}"
      extension = extensions.delete('wmf')
      extension ||= extensions.delete('jpg')
#      extension ||= extensions.delete('jpeg')
      extension ||= extensions.delete('png')
    end
    background = file_pattern.gsub('*', extension)
    gtk_background = gtk_file_pattern.gsub('*', extension)

    # capture image width/height
    x_origin = 0
    y_origin = 0
    if File.exists? background
      gtk_filename_without_extension = File.basename(gtk_background, extension)
      image = MiniMagick::Image.open(background)
      # decrease size of picture
      if image['width'] > IMAGE_MAX_WIDTH or image['height'] > IMAGE_MAX_HEIGHT
        if image['format'].downcase == 'wmf'
          # convert wmf to png
          $logger.debug "NAVIKART: image #{background.inspect} is WMF, convert to PNG: #{gtk_filename_without_extension.inspect}png"
          image.format('png')
        end
        # resize to fit
        $logger.debug "NAVIKART: image #{background.inspect} too big, resize while keeping ratio: #{gtk_background.inspect}"
        image.resize "#{IMAGE_MAX_WIDTH}x#{IMAGE_MAX_HEIGHT}>"
        background = grafik_resized_dir + gtk_filename_without_extension + image['format'].downcase
        image.write(background)
        extension = image['format'].downcase
      else
        background_new = grafik_resized_dir + File.basename(background)
        if not File.exists? background_new
          FileUtils.cp(background, background_new)
        end
        background = background_new
      end

      x_origin = image['width'].to_f
      y_origin = image['height'].to_f
    else
      extension = nil
    end
    kartei_hash = KarteiHash.new({'0'=>gtk_record, '1'=>nk.name, '2' => 0, '30' => extension})
    output.puts kartei_hash.to_s

    ## add default layer
    layer_ident = "#{gtk_record}_LAYER1"
    layer_hash = KarteiHash.new({'0'=>layer_ident, '1'=>'Layer 1', '2' => 1, '3' => "#{gtk_record}"})
    output.puts layer_hash.to_s

    ## parse hotlinks within navikart and create record for each
    links = nk.to_hash.select {|k,v| (k =~ /^hot/ and v) }
    links = Hash[links]
    link_keys = links.keys.sort
    link_keys.each_with_index do |key, i|

      $logger.debug "HOTSPOT: parse #{links[key].inspect}"

      empty, label, x, y, destination, x1, y1 = links[key].split('~')
      hotspot_ident = "#{gtk_record}_HOTSPOT#{i+1}"

      if label 
        horizontal_text_orientation = case label[0..0]
          when '-'  then 0
          when '\\' then 1
          when '+'  then 2
          else 1
        end
        label.gsub!(/^[\+\-\\]/, '')                  # remove from label
      end
          
      # see new navikart.def for column descriptions
      hotspot_hash = {}
      hotspot_hash['0'] = hotspot_ident             # compose ident
      hotspot_hash['1'] = label
      hotspot_hash['2'] = 2                         # type is hotspot
      hotspot_hash['3'] = "#{gtk_record}"
      hotspot_hash['4'] = layer_ident
      hotspot_hash['50'] = horizontal_text_orientation
      hotspot_hash['51'] = 0                        # vertical orientation: 0=baseline, 1=zentriert, 2=topline
      # TODO calculate relative x and y coordinates
      if File.exists? background
        ratio = 720.0 / 540.0
        x_offset = 0
        y_offset = 0
        resized_height = y_origin
        resized_width = x_origin
        dimension_correction = x_origin/y_origin - ratio
        $logger.debug "Image #{x_origin}x#{y_origin}"
        if dimension_correction > 0
	        resized_height = x_origin / ratio
          y_offset = (resized_height - y_origin) / 2
          $logger.debug "rescale hotspot Y-coordinates: #{y_origin}, #{resized_height}, #{y_offset}"
        elsif dimension_correction < 0
          resized_width = y_origin * ratio
          x_offset = (resized_width - x_origin) / 2
          $logger.debug "rescale hotspot X-coordinates: #{x_origin}, #{resized_width}, #{x_offset}"
        else
          # no offset
        end
#        x_abs = x_origin / 720.0 * x.to_f         # calculate x absolute position from old lageplan size (small,medium,large); medium=720
#        y_abs = y_origin / 540.0 * y.to_f         # calculate y absolute position from old lageplan size (small,medium,large); medium=540
        x_abs = (x.to_f / 720.0 * resized_width) - x_offset         # calculate x absolute position from old lageplan size (small,medium,large); medium=720
        y_abs = (y.to_f / 540.0 * resized_height) - y_offset
        x_abs = x_abs+x_offset if x_abs < 0
        y_abs = y_abs+y_offset if y_abs < 0

        $logger.debug "rescaled hotspot coordinates: #{x_abs}x#{y_abs}"

        x_rel = 100.0 * x_abs / (x_origin)            # calculate x relative coordinates
        y_rel = 100.0 * y_abs / (y_origin)            # calculate y relative coordinates
        hotspot_hash['6'] = x_rel
        hotspot_hash['7'] = y_rel
      else
        # image not found
        hotspot_hash['6'] = 0
        hotspot_hash['7'] = 0
      end

      # determine link destination
      if destination and not destination.empty?
        destination_type, destination_ident = destination.split(':', 2)
        case destination_type.to_s
          when /lgp/i
            hotspot_hash['5'] = 0
            $logger.debug "HOTSPOT: looking up lageplan1 destination: #{destination.inspect}"
            destination_name = destination_ident || destination
            Kartei::Navikart.search_by_tree(:baum => 0, :von => {:name => destination_name}).each do |dest_nk, dest_record, dest_satz|
              tmp_dest_record = dest_record
              dest_record[0] = 'G'
              hotspot_hash['8'] = tmp_dest_record
              hotspot_hash['9'] = destination_name
            end
          when /art/i
            hotspot_hash['5'] = 1
            $logger.debug "HOTSPOT: looking up artikel1 destination: #{destination_ident.inspect}"
            artikel = Kartei::Artikel.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = artikel.such1 rescue 'Artikel nicht gefunden'
          when /gbd/i
            hotspot_hash['5'] = 2
            $logger.debug "HOTSPOT: looking up gebaeude1 destination: #{destination_ident.inspect}"
            gebaeude = Kartei::Artikel.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = gebaeude.such1 rescue 'Gebaeude nicht gefunden'
          when /pkt/i
            hotspot_hash['5'] = 3
            $logger.debug "HOTSPOT: looking up fdspunkt1 destination: #{destination_ident.inspect}"
            fdspunkt = Kartei::Fdspunkt.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = fdspunkt.feldadr rescue 'Datenpunkt nicht gefunden'
          when /sys/i
            hotspot_hash['5'] = 4
            $logger.debug "HOTSPOT: looking up system(Panorama)1 destination: #{destination_ident.inspect}"
          when /adr/i
            hotspot_hash['5'] = 5
            $logger.debug "HOTSPOT: looking up adresse1 destination: #{destination_ident.inspect}"
            adresse = Kartei::Adresse.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = adresse.such1 rescue 'Adresse nicht gefunden'
          when /ord/i
            hotspot_hash['5'] = 6
            $logger.debug "HOTSPOT: looking up ordner1 destination: #{destination_ident.inspect}"
            ordner = Kartei::Ordner.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = ordner.such1 rescue 'Ordner nicht gefunden'
          when /dsr/i
            hotspot_hash['5'] = 7
            $logger.debug "HOTSPOT: looking up dossier1 destination: #{destination_ident.inspect}"
            dossier = Kartei::Dossier.find(3, destination_ident)
            hotspot_hash['8'] = destination_ident # is this correct?
            hotspot_hash['9'] = dossier.such1 rescue 'Dossier nicht gefunden'
          else
            case nk.gbdeliste.to_s
              when /0/ # Artikel
                hotspot_hash['5'] = 1
                $logger.debug "HOTSPOT: looking up artikel2 destination: #{destination.inspect}"
                artikel = Kartei::Artikel.find(3, destination)
                hotspot_hash['8'] = destination # is this correct?
                hotspot_hash['9'] = artikel.such1 rescue 'Artikel nicht gefunden'
              when /1/ # Gebäude
                hotspot_hash['5'] = 2
                $logger.debug "HOTSPOT: looking up gebaeude2 destination: #{destination.inspect}"
                gebaeude = Kartei::Artikel.find(3, destination)
                hotspot_hash['8'] = destination # is this correct?
                hotspot_hash['9'] = gebaeude.such1 rescue 'Gebaeude nicht gefunden'
              when /2/ # Lageplan
                hotspot_hash['5'] = 0
                $logger.debug "HOTSPOT: looking up lageplan2 destination: #{destination.inspect}"
                destination_name = destination || destination
                Kartei::Navikart.search_by_tree(:baum => 0, :von => {:name => destination_name}).each do |dest_nk, dest_record, dest_satz|
                  tmp_dest_record = dest_record
                  tmp_dest_record[0] = 'G'
                  hotspot_hash['8'] = tmp_dest_record
                  hotspot_hash['9'] = destination_name
                end
              when /3/ # System
                hotspot_hash['5'] = 4
                $logger.debug "HOTSPOT: looking up system(Panorama) destination: #{destination_ident.inspect}"
              else
                $logger.debug "HOTSPOT: no destination type given"
            end
        end
      else
        $logger.debug "HOTSPOT: no destination given, omit destination ..."
      end

      # find out function for datapoint (see NAVIKART_LABEL_WIDGETS)
      if label =~ /\[/
        f = label.scan(/\[\d*([^\[\]]+)\]/).first.first
        if f.strip.empty?
          # no special link, only "[  ]" as label ...
        else
          func[f] ||= 0
          func[f] += 1
          hotspot_hash['1'] = NAVIKART_LABEL_WIDGETS[f]
        end
      end

      # write hotspot record to file
      output.puts KarteiHash.new(hotspot_hash).to_s

    end
  end
end

Dir["#{grafik_resized_dir}NK0*"].each do |f|
  filename = File.basename(f)
  new_filename = filename.gsub(/NK0/, "NKG")
  $logger.debug "GRAFIK: rename #{filename} to #{new_filename}"

  File.rename(f, File.dirname(f) + new_filename)
end

$logger.info func.inspect
