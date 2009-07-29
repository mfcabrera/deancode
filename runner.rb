
require 'forecast_downloader'
require 'executor'
#Runs the executor

utc = ARGV[0]


if  ["0","6","12","18","last"].include?(utc)
  pr =  ForecastDownloader::Executor.new
  if utc == "last"
    #try to get the current utc offset
    hour = Time.now.utc.hour 
    utc = [0,6,12,18].find {|t| t <= hour } || 18
  end
  pr.perform(utc)
else
  raise ArgumentError, "UTC param should be one of [0,6,12,18,last]"
end
