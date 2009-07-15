require 'rubygems'
require 'yaml'
require 'curl'
require 'logger' 
require 'singleton'
require 'sequel'
require 'forecast_downloader'
require 'model/point.rb'
include ForecastDownloader

module ForecastDownloader
  class Executor
    
    #This class has the logic of how use all the classes defined 
    #in this particular package. It orchestrates all the process of
    #Getting the forecast from the NOAA Website to the DB including
    #Performing the surfsize algortithm
    
    def initialize
    end
    
    
    def perform(utc=0,date=nil)
      
      if not  ["0","6","12","18"].include?(utc)
        raise ArgumentError, "UTC param should be one of [0,6,12,18]"
      end
        
      #Que the list of points
      @points = Model::Point.find_all
      
      max_lon = Model::Point.max_lon.to_f + 1
      min_lon = Model::Point.min_lon.to_f - 1
      max_lat = Model::Point.max_lat.to_f + 1
      min_lat = Model::Point.min_lat.to_f - 1
      
      zone = ForecastZone.new(max_lat,min_lat,min_lon,max_lon,utc) 
      date = date || Date.today.strftime("%Y%m%d")
      gd = GribDownloader.new(zone,date)
      filename = gd.filename
      gd.download

      wg = Wgrib2Frontend.new(filename,Model::Point.find_all.to_a,"#{filename}.csv")
      wg.execute_wgrib2      
      gdi = GribDataImporter.new
      gdi.load_from_file("#{filename}.csv")      
         
    end        
    
    
    def calculate_surf_size()
      #FIXME GET THE RIGHT VALUES HERE CREATE THE CALCULATION
      forecast_dates =   Model::Forecast.select(:forecast_date).order(:forecast_date).distinct.to_a
      foreacst_dates.each do |fd| 
        Model::Forecast.filter(:forecast_date => fd.forecast_date).each {|f| puts "#{f.var_name}-#{f.value} "}               
        
      end
      
    end

  end
end
