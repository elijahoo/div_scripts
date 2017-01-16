
#require '/sfmtool/prg/opt/interface/lib/bootstrap'
require 'rubygems'
require 'kartei'
require 'pg'


unless ARGV[0]
  raise "USAGE: ruby relation.rb <MANDANT>"
end
MANDANT = ARGV[0]
DATABASE = ARGV[0].downcase
USER = 'reporting_' + DATABASE

$data = []

def execute_batch(sql_statements)
  conn = PGconn.open(:dbname => DATABASE)
  conn.set_error_verbosity(PGconn::PQERRORS_TERSE)

  sql_statements.each do |sql|
    begin
      p sql
      res = conn.exec(sql)
    rescue Exception => e
      puts "\t#{e.message.strip}"
    end
    puts ""
  end
  conn.close
end

def read_def(zokname)
puts "in read_def()"
  column_name_aliases = []
  if File.exists? zokname
    File.open(zokname, 'r').each do |line|
      if line =~ /^\)C relation:/
  puts "C"
        line.strip!
        blubb, blabb, name, one_relation, n_relation, conditions = line.split(/\s/, 6)
        if name and one_relation and n_relation
          foreign_table, foreign_key, strip_foreign_key_length = one_relation.split(':', 3)
          primary_table, primary_key, strip_primary_key_length = n_relation.split(':', 3)

          $data << {:tabellenname => zokname, :view_alias => name, :foreign_table => foreign_table, :foreign_key => foreign_key, :primary_key => primary_key, :strip_foreign_key_length => strip_foreign_key_length.to_i, :strip_primary_key_length => strip_primary_key_length.to_i, :conditions => conditions }
        end
      elsif line =~ /^\)X/
  puts "X"
        f = line.split(/\s+/).map(&:downcase)
        $data << { :tabelle_column_name => f[1], :tabelle_column_aliases => f[2] }
      end
    end
  end
end


Thread.current[:mandant] = MANDANT

sql = []
views = []

Dir["/sfmtool/prg/def/*.def"].each do |def_file|
  puts def_file
  read_def(def_file)
  $data.each do |d|
#    puts "#{d[:tabellenname]}"
  end
end

$data.each do |rel|
#  sql << 
end




execute_batch(sql)
