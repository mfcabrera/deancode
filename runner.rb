
require 'forecast_downloader'
require 'executor'
#Runs the executor

if ARGV.size < 1
  puts "usage: #{$0} <utc> [<date>]"
  puts "utc: the utc value for the NOAA calculatiion,  one of [0 6 12 18]."
  puts "date: in yyyymmdd format."
  exit
end

utc = ARGV[0]
date = ARGV[1]

if  ["0","6","12","18","last"].include?(utc)
  pr =  ForecastDownloader::Executor.new
  if utc == "last"
    #try to get the current utc offset
    if date.nil? #we try to select the adequate params
      
      utday = Time.now.utc.day
      day = Time.now.day
      umonth = Time.now.utc.month
      umonth = Time.now.month
      hour = Time.now.utc.hour 

      nowt = Time.now
      utct = Time.now.utc
      utc_key = "#{utct.year}#{utct.month}#{utct.day}".to_i
      now_key = "#{nowt.year}#{nowt.month}#{nowt.day}".to_i

      if utc_key > now_key
        hour = hour + 12
      end
      
      if utc_key < now_key
        hour = hour - 12
      end
      
      utc = [0,6,12,18].reverse.find {|t| t < hour  } || 18
      
      puts utc
      
    else
      raise "You should specify a numeric UTC when specifying the date"
      
    end
  end
  if(date.nil?)
    pr.perform(utc)
  else
    pr.perform(utc,date)    
  end
else
  raise ArgumentError, "UTC param should be one of [0,6,12,18,last]"
end
