
require 'forecast_downloader'

utc = ARGV[0]

if utc.is_int? and ["0","6","12","18"].include?(utc)
  pr =  ForecastDownloader::Processor.new(utc)
  pr.perform
else
  raise ArgumentError, "UTC param should be one of [0,6,12,18]"
end
