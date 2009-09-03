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
      @swclas_calc = SwellClassCalculator.new
    end
    
    
    def perform(utc=0,date=nil)
      
      if not  ["0","6","12","18"].include?(utc.to_s)
        raise ArgumentError, "UTC param should be one of [0,6,12,18]"
      end

      if date.nil?
        if Time.now.hour < utc.to_i
          raise ArgumentError, "requested forecast generation time cannot be in the future #{utc} >  #{Time.now.hour}"
        end
      end
      
      
      #Que the list of points
      @points = Model::Point.find_all
      
      max_lon = Model::Point.max_lon.to_f + 1
      min_lon = Model::Point.min_lon.to_f - 1
      max_lat = Model::Point.max_lat.to_f + 1
      min_lat = Model::Point.min_lat.to_f - 1
      
      
      hour  = Time.now.utc.hour
      nhour = Time.now.hour

      if date.nil?
        if ((Time.now.utc.yday > Time.now.yday) and (hour > utc.to_i + 5))
          date =  Time.now.utc.to_datetime.strftime("%Y%m%d")
        else
          date =  Time.now.to_datetime.strftime("%Y%m%d")
          #utc = [0,6,12,18].find {|t| t > nhour } || 18
        end
      end
      
      zone = ForecastZone.new(max_lat,min_lat,min_lon,max_lon,utc) 
      
      #FIXME validate the format of date or expect a Date object
        

      
      @log.info("Downloadimg forecast for #{date} calculated in UTC: #{utc}")
      
      gd = GribDownloader.new(zone,date)
      filename = gd.filename
      gd.download

      wg = Wgrib2Frontend.new(filename,Model::Point.find_all.to_a,"#{filename}.csv")
      wg.execute_wgrib2      
      gdi = GribDataImporter.new(filename,date)
      gdi.load_from_file("#{filename}.csv")      
      calculate_derived_measures
         
    end        
    
    def calculate_derived_measures()
      #FIXME GET THE RIGHT VALUES HERE CREATE THE CALCULATION
     
      @log.info("Calculating the surf size and swell class  for the forecast")
      fdates =   Model::Forecast.select(:forecast_date,:lat,:lon).order(:forecast_date).distinct.to_a
      fdates.each do |fd| 

        x = Model::Forecast.filter('forecast_date = ? and lat = ? and lon = ?',fd.forecast_date,fd.lat,fd.lon).to_a
        #x = Model::Forecast.filter('forecast_date = ? and lat = ? and lon = ?',fd.forecast_date)
        h_0 = p = nil
        wvper = perpw = persw = nil
        x.each do |forecast|
          

          if forecast.var_name == "HTSGW"
            h_0 = forecast.value            
          end
          
          #we chose one of these period based if the appear
          #in this seame order

          if forecast.var_name == "PERPW" 
            perpw = forecast.value
          end                    
          
          if forecast.var_name == "PERSW" 
            persw = forecast.value
          end                    
          
          if forecast.var_name == "WVPER" 
            wvper = forecast.value
          end                    
        
          
        end

        p = perpw || persw || wvper 

        
        if h_0.nil? or p.nil?
          #raise  "HTSGW or PERPW not properly defined for this  forecast"
          @log.warn "HTSGW or PERPW not properly defined for this  forecast"
          p = p || 0.0
          h_0 = h_0 || 0.0
        end
        

        #Let's calculate the surf size and create a new forecast entry
        surf_size = @surf_calc.calculate(h_0,p)
        swell_class = @swclas_calc.calculate(h_0,p)
        
        #Copy over the same values from one of the Forecasts for Surf Size
        sample = x.to_a[0]
        surf_entry = Model::Forecast.new
        surf_entry.var_name="SURFZ"
        surf_entry.grib_date = sample.grib_date
        surf_entry.forecast_date = sample.forecast_date
        surf_entry.lat = sample.lat
        surf_entry.lon = sample.lon
        surf_entry.value = surf_size
        surf_entry.save

        #Copy over the same values from one of the Forecasts for Swell Class
        swell_class_entry = Model::Forecast.new
        swell_class_entry.var_name="SWELLC"
        swell_class_entry.grib_date = sample.grib_date
        swell_class_entry.forecast_date = sample.forecast_date
        swell_class_entry.lat = sample.lat
        swell_class_entry.lon = sample.lon
        swell_class_entry.value = swell_class
        swell_class_entry.save

        
        # @log.info("Surf Size for #{surf_entry.forecast_date} = #{surf_size}")      
      end
    

      @log.info("Surf size and swell calculation  process finished")
    end    
    
  end
end