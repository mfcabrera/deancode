
#We make inherit from SequelModel directly.
require 'rubygems'
require 'yaml'
require 'sequel'

module ForecastDownloader
  module Model
  
  CONNECTION_STRING = YAML.load_file(File.dirname(__FILE__)+ "/../settings.yml")["db"]

  DB = Sequel.connect(CONNECTION_STRING)
  class Point  < Sequel::Model(:forecast_points)

    def[](index)
      if index == 0
        @lon
      elsif index == 1
        @lat
      else
        nil
      end
    end
    
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
