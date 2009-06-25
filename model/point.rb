
#We make inherit from SequelModel directly.
require 'rubygems'
require 'yaml'
require 'sequel'
require 'forecast_downloader'
include ForecastDownloader

module ForecastDownloader
  module Model
    
    config = YAML.load_file(File.dirname(__FILE__)+ "/../settings.yml")
    CONNECTION_STRING = config["db"][config["env"]]
    ::MyLogger.instance.debug("Using db connection #{CONNECTION_STRING}") 
    DB = Sequel.connect(CONNECTION_STRING)
    class Point  < Sequel::Model(:forecast_points)
      
 #    def[](index)
#       if index == 0
#         self.
#       elsif index == 1
#         @lat
#       else
#         nil
#       end
#     end
    
    def validate_params(lat,lon)
      if (lon < -180 or lon > 180)
        raise ArgumentError,"Invalid value for longitude: Should be between
  -180 and +180"
      end
      if (lat < -90 or lat > 90)
        raise ArgumentError,"Invalid value for latitude: Should be between
  -90 and +90"
      end
    end
      
      #   def initialize(lat,lon,name="")
      #     validate_params(lat,lon)
      #     @lon,@lat,@name = lon,lat,name        
      #   end
      # end
    end
  end
end
