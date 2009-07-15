
#We make inherit from SequelModel directly.
require 'rubygems'
require 'yaml'
require 'sequel'
require 'forecast_downloader'
include ForecastDownloader

module ForecastDownloader
  module Model
    Sequel.datetime_class = DateTime
    config = YAML.load_file(File.dirname(__FILE__)+ "/../settings.yml")
    CONNECTION_STRING = config["db"][config["env"]]
    ::MyLogger.instance.debug("Using db connection #{CONNECTION_STRING}") 
    DB = Sequel.connect(CONNECTION_STRING)
    class Point  < Sequel::Model(:forecast_points)
      
      def[](index)
        if index == 0
          @values[:lat]
        elsif index == 1
          @values[:lon]
        else
          nil
        end
      end
      
      def_dataset_method(:max_lat) do
        get {|o| o.max(:lat) }        
      end
      
      def_dataset_method(:min_lat) do
        get {|o| o.min(:lat) }        
      end
      
      def_dataset_method(:min_lon) do
        get {|o| o.min(:lon) }        
      end

      def_dataset_method(:max_lon) do
        get {|o| o.max(:lon) }        
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
