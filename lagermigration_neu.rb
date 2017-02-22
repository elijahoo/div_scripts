#
# Aufruf: ruby /sfmtool/prg/lager_migration.rb {Mandant}
#

require 'fileutils'
require 'logger'

require 'rubygems'
require 'kartei'

MANDANT = ARGV[0]

STDOUT.sync = true
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{Thread.current[:mandant]}] #{severity}: #{msg}\n"
end

$logger.info( "--- START ---")

Kartei::Karteikasten.logger = $logger

PRG = "/sfmtool/prg"
EXP = "#{PRG}/migration/v3.2.8.0"


#
# Alle relevanten Karteikästen mit betreffenden Variablen
#
LAGER_REFERENCE_TABLES = { 
  Kartei::Artaswgrd => [ 38 ],
  Kartei::Artikel   => [ 106 ],
  Kartei::Benutzer  => [ 23 ],
  Kartei::Fmkvrbzhl => [ 16 ],
  Kartei::Fremdsys  => [ 15 ],
  Kartei::Ihauftr   => [ 33 ],
  Kartei::Ihaufwnd  => [ 20 ],     # Name in Var 19
  Kartei::Ihbenein  => [ 12 ],
  Kartei::Lgrausw   => [ 8  ],     # Name in Var 19
  Kartei::Lgrbstnd  => [ 11 ],     # Name in Var 60
  Kartei::Lgrhist   => [ 11, 13 ], # Name in Var 60 & 61
  Kartei::Lgrmbok   => [ 11 ],     # Name in Var 60
  Kartei::Lgrmbst   => [ 11 ],     # Name in Var 60
  Kartei::Lgrplan   => [ 11, 13 ], # Name in Var 60 & 61
  Kartei::Vorgang   => [ 66, 69 ]
}


def check()
  if not File.exists? "#{PRG}/def/lgrregal.def"
    abort("Die Lagermigration nach der Installation des Release 3.2.8.0 gemacht werden. Die nicht vorhandene Datei #{PRG}/def/lgrregal.def deutet darauf hin, dass das Release 3.2.8.0 noch nicht installiert wurde.")
  end
end

#
# Altdaten sichern
#
def backup(mandant)
  timestring = Time.now.strftime('%Y-%m-%d-%H%M%S')
  backup_target = "/sfmtool/save/#{timestring}_#{mandant.dir_name}_lagermigration.tar.gz"
  $logger.info "Erstelle Sicherung #{backup_target.inspect}"

  # alle Karteikasten und Ticket-Dateien sichern  
  system( "tar -czf #{backup_target} #{mandant.dir_name}/*.*" )
end


def prepare(mandant)
  #
  # Artikelklasse für Lagerorte bei Bedarf ergänzen
  #
  artklass_lager = Kartei::Artklass.find( 0, "LG" )
  unless artklass_lager
   artklass_lager = Kartei::Artklass.new
   artklass_lager.ident = "LG"
   artklass_lager.name = "Lagerort"
   artklass_lager.save
  end
  $artklass_name = sprintf("%s %s", artklass_lager.ident, artklass_lager.name)
 
  FileUtils.mkdir_p("#{EXP}/#{mandant.dir_name}")
end

def export(mandant)
  #
  # Mache export von Karteikasten und backup der Altdaten
  #
  $logger.info "exportiere Karteikasten ..."
  
  LAGER_REFERENCE_TABLES.keys.each do |klass|
    krtname = klass.zok
    if system( "/sfmtool/uti/linux/kkpexpor #{PRG}/def/#{krtname} #{PRG}/#{mandant.dir_name}/#{krtname} #{EXP}/#{mandant.dir_name}/#{krtname}.exp" )
      $logger.info "+ #{krtname} (OK)"
    else
      $logger.error "- #{krtname} (ERROR)"
    end
  end
end

def convert_lagerort_to_artikel
  $logger.info "Erstelle Artikel aus Lagerorte ..."
  lagerorte_hash = {}
  lagerorte = Kartei::Lagerort.all
  lagerorte.each do |lager|
    a = create_lagerort_artikel(lager.nummer, lager.kurztext)
    lagerorte_hash.store(lager.nummer, a)
  end
  return lagerorte_hash
end

def create_regale()
  $logger.info "Erstelle Regale aus Lagerbestaende ..."

  regale = {}
  lgrbstnd = Kartei::Lgrbstnd.tree_search(:baum => 0, :von => '', :bis => "\376\376") do |id, suchstring|
    if not suchstring['regal'].empty? and not regale.has_key? suchstring['regal']
      regale.store(suchstring['regal'], suchstring['lgr1tck'])
    end
  end

  regale.each do |regal, lagerort_ticket|
    if not Kartei::Artikel.find(0, lagerort_ticket)
      $logger.warn "Lagerort mit Ticket #{lagerort_ticket.inspect} existiert nicht ..."
    elsif Kartei::Lgrregal.find(0, :arttick => lagerort_ticket, :kennung => regal)
      $logger.warn "Regal #{regal.inspect} existiert bereits ..."
    else
      r = Kartei::Lgrregal.new
      r.arttick = lagerort_ticket
      r.kennung = regal
      r.text = regal
      if not r.save
        $logger.warn "Regal #{suchstring['regal'].inspect} konnte nicht gespeichert werden."
      end
    end

  end

  return regale
end

def create_lagerort_artikel(lager_nummer, lager_name, status = 0)
  artikel_nummer = "LG-#{lager_nummer}"

  lagerort_artikel = Kartei::Artikel.find( 3, artikel_nummer )
  if not lagerort_artikel
    lagerort_artikel = Kartei::Artikel.new
    lagerort_artikel.nummer = artikel_nummer
    if lager_name.nil?
      lagerort_artikel.name1  = "Lager #{lager_nummer}"
    else
      lagerort_artikel.name1  = "#{lager_name}"
    end
    lagerort_artikel.such1  = "Lager #{lager_nummer}"
    lagerort_artikel.klasse = $artklass_name
    lagerort_artikel.status = status
    lagerort_artikel.inbetrieb = 0
    lagerort_artikel.art = 11
    lagerort_artikel.istlager = true
    if not lagerort_artikel.save
      $logger.warn "Artikel #{a.nummer} konnte nicht gespeichert werden (Lagerort=#{lager_nummer})"
    end
  end

  return lagerort_artikel
end

def update_lagerort_references(mandant, lagerorte_hash)
  $logger.info( "Ersetze Lagerort Referenzen mit Lagerort Artikel-Ticket ...")

  LAGER_REFERENCE_TABLES.each do |klass, krt_lgr_varnr_array|
    krtname = klass.zok
    $logger.info( "+ #{krtname}" )
    
    tupel = {}
    changes = []

    file = File.open( "#{EXP}/#{mandant.dir_name}/#{krtname}.exp", 'r').each do |line|
      nr, val = line.strip.split(/\s{1}/, 2)
      tupel.store(nr, val)
      if nr == '.'
        unless changes.empty?
          k = klass.load(val.strip) # load by record
          changes.each do |column_id, column_val|
            k.set_var(column_id, column_val) # change columns by id
          end
          k.save
        end
        changes = []
        tupel = {}
      elsif krt_lgr_varnr_array.include? nr.to_i and not Kartei::Artikel.find(0, val) # check if lagerort already created
        lager_nummer = val[0,2]
        lagerort_artikel = lagerorte_hash[lager_nummer] 
        
        unless lagerort_artikel
          $logger.warn "Lager #{lager_nummer.inspect} nicht gefunden, erstelle einen archivierten Artikel Lagerort."

          lagerort_artikel = create_lagerort_artikel(lager_nummer, nil, 2)
          lagerorte_hash.store(lager_nummer, lagerort_artikel)
        end

        changes << [nr, lagerort_artikel.ticket]

        # special case
        if nr == "11" then
          changes << [60, lagerort_artikel.name1]
        elsif nr == "13" then
          changes << [61, lagerort_artikel.name1]
        elsif nr == "20" then
          changes << [19, lagerort_artikel.name1]
        elsif nr == "08" then
          changes << [9, lagerort_artikel.name1]
        end
      end

    end
  end

  return lagerorte_hash
end

#
# START -> main()
# 

Thread.current[:mandant] = 'Muster'

check()

mandanten = Kartei::Mandant.all
for mandant in mandanten
  if MANDANT.nil? or MANDANT == mandant.ident
    if not mandant.directory?
      $logger.warn "Mandantenverzeichnis #{mandant.path.inspect} nicht gefunden, ueberspringe Mandant #{mandant.ident}."
    else
      Thread.current[:mandant] = mandant.ident
      backup(mandant)
      prepare(mandant)
      
      lagerorte_hash = convert_lagerort_to_artikel()
      
      if lagerorte_hash.empty?
        $logger.info "Ueberspringe Lagerorte/Regal Migration, da keine Lagerorte in den Grunddaten."
      else
      
        export(mandant)
        
        update_lagerort_references(mandant, lagerorte_hash)
        
        create_regale()
      end

    end
  end
end

$logger.info( "--- ENDE ---")

exit
