
require 'forecast_downloader'
require 'executor'
#Runs the executor

utc = ARGV[0]
date = ARGV[1]

if  ["0","6","12","18","last"].include?(utc)
  pr =  ForecastDownloader::Executor.new
  if utc == "last"
    #try to get the current utc offset
    hour = Time.now.utc.hour 
    utc = [0,6,12,18].find {|t| t <= hour } || 18
  end
  if(date.nil?)
    pr.perform(utc)
  else
    pr.perform(utc,date)    
  end
else
    raise ArgumentError, "UTC param should be one of [0,6,12,18,last]"
end
