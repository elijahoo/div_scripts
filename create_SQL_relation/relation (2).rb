
require 'rubygems'
require 'pg'

unless ARGV[0]
  raise "USAGE: ruby relation.rb <PG_DATABASE>"
end
DATABASE = ARGV[0].downcase
USER = 'reporting_' + DATABASE

# additional columns, which are not in the def, but are generated for primary-/foreign-key constraints
$special_columns = {}

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

def create_view_sql(zokname)
  column_name_aliases = []
  if File.exists? "/sfmtool/prg/def/#{zokname}.def"
    File.open("/sfmtool/prg/def/#{zokname}.def", 'r').each do |line|
      if line =~ /^\)X/
        f = line.split(/\s+/).map(&:downcase)
        if f.size == 3
          column_name_aliases << [f[1], f[2].gsub(/\W/, '_')]
        else
          puts "Unknown column name/alias for table #{zokname} => #{f.inspect}"
        end
      end
    end
    def_columns = column_name_aliases.map {|tech_name, human_name| "#{tech_name} as #{human_name}" }
    columns = $special_columns[zokname] ? ($special_columns[zokname] | def_columns) : def_columns
    return "SELECT #{columns.join(',')} FROM #{zokname}"
  else
    return "SELECT * FROM #{zokname}"
  end
end

#raise create_view_sql('position')

# collect relations
relations = []
File.open('relation.txt', 'r').each do |line|
  if line !~ /^\#/
    line.strip!
    name, one_relation, n_relation, conditions = line.split(/\s/, 4)
    if name and one_relation and n_relation
      primary_table, primary_key = one_relation.split(':', 2)
      foreign_table, foreign_key, strip_foreign_key_length = n_relation.split(':', 3)

      $special_columns[foreign_table] ||= ['id']
      $special_columns[foreign_table] << "#{name}_id"

      relations << {:name => name, :primary_table => primary_table, :primary_key => primary_key, :foreign_table => foreign_table, :foreign_key => foreign_key, :strip_foreign_key_length => strip_foreign_key_length.to_i, :conditions => conditions }
    end
  end
end

sql = []
views = []

relations.each do |rel|  
  sql << "ALTER TABLE #{rel[:primary_table]} ADD CONSTRAINT #{rel[:primary_table]}_id UNIQUE (id);"
  sql << "ALTER TABLE #{rel[:foreign_table]} ADD COLUMN #{rel[:name]}_id integer;"
  sql << "ALTER TABLE #{rel[:foreign_table]} ADD CONSTRAINT #{rel[:name]} FOREIGN KEY (#{rel[:name]}_id) REFERENCES #{rel[:primary_table]} (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;"
  sql << "CREATE INDEX fki_#{rel[:name]} ON #{rel[:foreign_table]}(#{rel[:foreign_key]});"
  
  update_sql = "UPDATE #{rel[:foreign_table]} t2 SET #{rel[:name]}_id = (SELECT id FROM #{rel[:primary_table]} t1 WHERE t1.#{rel[:primary_key]} = t2.#{rel[:foreign_key]}"
  if not rel[:strip_foreign_key_length].zero?
    update_sql = "UPDATE #{rel[:foreign_table]} t2 SET #{rel[:name]}_id = (SELECT id FROM #{rel[:primary_table]} t1 WHERE t1.#{rel[:primary_key]} = trim(both ' ' from substring(t2.#{rel[:foreign_key]} from 1 for #{rel[:strip_foreign_key_length]}))"
  end

  update_sql << " AND #{rel[:conditions]}" if rel[:conditions] and not rel[:conditions].empty?
  update_sql << " LIMIT 1);"

  sql << update_sql

  views << rel[:primary_table]
  views << rel[:foreign_table]
end

sql << "REVOKE ALL ON DATABASE #{DATABASE} FROM #{USER};"
views.uniq.each do |table|
  sql << "REVOKE ALL ON TABLE #{table} FROM #{USER};"
end
sql << "DROP USER IF EXISTS #{USER};"
sql << "CREATE USER #{USER} LOGIN CONNECTION LIMIT -1 UNENCRYPTED PASSWORD 'reporting';"

#sql << "DROP SCHEMA IF EXISTS #{USER} CASCADE;"
#sql << "CREATE SCHEMA AUTHORIZATION #{USER};"

sql << "GRANT ALL ON DATABASE #{DATABASE} TO #{USER};"

views.uniq.each do |table|
#  view = "#{USER}.vw_#{table}"
  view = "public.vw_#{table}"
  sql << "DROP VIEW IF EXISTS #{view};"
  sql << "CREATE VIEW #{view} AS #{create_view_sql(table)};"
  sql << "GRANT SELECT ON TABLE #{view} TO #{USER};"
  sql << "GRANT REFERENCES ON TABLE #{view} TO #{USER};"

#  sql << "GRANT SELECT ON TABLE public.#{table} TO #{USER};"
#  sql << "GRANT REFERENCES ON TABLE public.#{table} TO #{USER};"
  sql << "GRANT ALL ON TABLE #{table} TO #{USER};"

end

execute_batch(sql)

