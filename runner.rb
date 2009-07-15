
require 'forecast_downloader'
require 'executor'
#Runs the executor

utc = ARGV[0]

if  ["0","6","12","18"].include?(utc)
  pr =  ForecastDownloader::Executor.new
  pr.perform(utc)
else
  raise ArgumentError, "UTC param should be one of [0,6,12,18]"
end
