require 'rubygems'
require 'kartei'

require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO
Kartei::Karteikasten.logger = logger

Thread.current[:mandant] = ARGV[0]

logger.info "Bestandsdaten mit Lager/Regalen suchen"
lgrartorts = {}
Kartei::Lgrbstnd.tree_search_all do |id, s|
#  print '.'
  if not s['regal'].empty?
    data = {:matarttick => s['arttick'], :lgrorttick => s['lgr1tck'], :regalid => s['regal']}
    if not lgrartorts.has_key? data.to_s
      lgrartorts.store(data.to_s, data)
    end
  end
end

logger.info "#{lgrartorts.size} Sollregale (lgrartort) werden angelegt"
keys = lgrartorts.keys.sort
keys.each do |k|
  fields = lgrartorts.fetch(k)
  mat = Kartei::Artikel.find(0, fields[:matarttick])
  lgr = Kartei::Artikel.find(0, fields[:lgrorttick])
#  rgl = Kartei::Lgrregal.find(0, {:arttick => fields[:lgrorttick], :kennung => fields[:regalid]})
#  rgl = Kartei::Lgrregal.search_by_tree(:baum => 0, :von => {:arttick => 'AR73189', :kennung => 'w'}).first.first rescue nil
  rgl = Kartei::Lgrregal.search_by_tree(:baum => 0, :von => {:arttick => fields[:lgrorttick], :kennung => fields[:regalid]}).first.first rescue nil
  if not mat 
    logger.warn "Lagerartikel nicht gefunden: #{fields.inspect}"
  elsif not lgr
    logger.warn "Lagerort-Artikel nicht gefunden: #{fields.inspect}"
  elsif not rgl
    logger.warn "Regal nicht gefunden: #{fields.inspect}"
  else
    l = Kartei::Lgrartort.new
    l.matarttick = mat.ticket
    l.matnr = mat.nummer
    l.matsb1 = mat.such1    
    l.lgrorttick = lgr.ticket 
    l.lgrortnr = lgr.nummer
    l.lgrortsb1 = lgr.such1
    l.regalid = rgl.kennung
    l.regaltext = rgl.text
    l.save
  end
end

logger.info "Fertig"