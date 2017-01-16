require 'logger'

require 'rubygems'
require 'kartei'
require 'date'

require '/sfmtool/prg/fds/bin/fds_driver.rb'


import_file = ARGV.first
raise "Datei #{import_file.inspect} existiert nicht ..." unless File.exists? import_file

logger = Logger.new("#{import_file}_ear_import.log")
logger.level = Logger::DEBUG

driver = FdsDriver.new('ear_import', logger, FdsDriver::LONG_FIFO)

feldadr = Array.new(4)
value   = Array.new(4)
File.open(import_file, 'r').each_with_index do |line, index|
  date, time, value[0], value[1], value[2], value[3] = line.strip.split("\t", 6)

  if index == 0
    feldadr[0] = value[0]
    feldadr[1] = value[1]
    feldadr[2] = value[2]
    feldadr[3] = value[3]
    next
  end

  timestamp = Time.parse(DateTime.strptime("#{date}", '%d.%m.%Y').strftime('%Y-%m-%d')+" #{time}")
  #DateTime.strptime("#{date}", '%d.%m.%Y').strftime('%Y/%m/%d')

  count = 0
  begin
    feldadr.each_with_index do |f, i|

      puts( "#{f}\t#{timestamp}\t#{value[i]}")
#        driver.send_insert_value_to_fds(f, value[i], timestamp)
      count += 1
    end
  rescue FdsCommunicationError => e
    puts e.message
#        puts e.backtrace.join("\n")
    retry if count <= 10
  rescue Exception => e
    puts e.message
    puts e.backtrace.join("\n")
    retry if count <= 10
  end

end


