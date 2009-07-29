require 'rubygems'
require 'yaml'
require 'curl'
require 'logger' 
require 'singleton'
require 'sequel'
require 'forecast_downloader'
require 'model/point'
require 'model/forecast'
require 'surf_size_calculator'
include ForecastDownloader

module ForecastDownloader
  class Executor
    
    #This class has the logic of how use all the classes defined 
    #in this particular package. It orchestrates all the process of
    #Getting the forecast from the NOAA Website to the DB including
    #Performing the surfsize algortithm
    
    def initialize
      @log = MyLogger.instance
      @surf_calc = SurfSizeCalculator.new
    end
    
    
    def perform(utc=0,date=nil)
      
      if not  ["0","6","12","18"].include?(utc.to_s)
        raise ArgumentError, "UTC param should be one of [0,6,12,18]"
      end

     
      if not Time.now.hour >= utc
        raise ArgumentError, "requested forecast generation time cannot be in the future #{utc} >  #{Time.now.hour}"        
      end
      
      
      #Que the list of points
      @points = Model::Point.find_all
      
      max_lon = Model::Point.max_lon.to_f + 1
      min_lon = Model::Point.min_lon.to_f - 1
      max_lat = Model::Point.max_lat.to_f + 1
      min_lat = Model::Point.min_lat.to_f - 1
      
      zone = ForecastZone.new(max_lat,min_lat,min_lon,max_lon,utc) 
      date = date || Time.now.to_datetime.strftime("%Y%m%d")

      @log.info("Downloadimg forecast for #{date} calculated in UTC: #{utc}")
      
      gd = GribDownloader.new(zone,date)
      filename = gd.filename
      gd.download

      wg = Wgrib2Frontend.new(filename,Model::Point.find_all.to_a,"#{filename}.csv")
      wg.execute_wgrib2      
      gdi = GribDataImporter.new
      gdi.load_from_file("#{filename}.csv")      
      calculate_surf_size
         
    end        
    
    def calculate_surf_size()
      #FIXME GET THE RIGHT VALUES HERE CREATE THE CALCULATION
     
      @log.info("Calculating the surf size for the forecast")
      fdates =   Model::Forecast.select(:forecast_date).order(:forecast_date).distinct.to_a
      fdates.each do |fd| 
        
        x = Model::Forecast.filter('forecast_date = ?',fd.forecast_date)
        h_0 = p = nil
        x.each do |forecast|
        
          
        #  puts forecast.var_name
          if forecast.var_name == "HTSGW"
            h_0 = forecast.value            
          end
          if forecast.var_name == "PERPW"
            p = forecast.value
          end                    
          
        end
        
        if h_0.nil? or p.nil?
          raise "Error, HTSGW or PERPW not properly defined for this  forecast"
        end

        #Let's calculate the surf size and create a new forecast entry
        surf_size = @surf_calc.calculate(h_0,p)
        
        #Copy over the same values from one of the Forecasts
        sample = x.to_a[0]
        surf_entry = Model::Forecast.new
        surf_entry.var_name="SURFZ"
        surf_entry.grib_date = sample.grib_date
        surf_entry.forecast_date = sample.forecast_date
        surf_entry.lat = sample.lat
        surf_entry.lon = sample.lon
        surf_entry.value = surf_size
        surf_entry.save
        # @log.info("Surf Size for #{surf_entry.forecast_date} = #{surf_size}")      
      end
    

      @log.info("surf Size Calculation process finished")
    end    
    
  end
end
