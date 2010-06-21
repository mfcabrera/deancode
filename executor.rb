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
require 'ap'
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
      
      nowt = Time.now
      utct = Time.now.utc
      utc_key = "#{utct.year}#{utct.month}#{utct.day}".to_i
      now_key = "#{nowt.year}#{nowt.month}#{nowt.day}".to_i

      if date.nil?
        if  utc_key == now_key and utct.hour < utc.to_i
          raise ArgumentError, "requested forecast generation time cannot be in the future #{utc} >  #{Time.now.utc.hour}"  
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
        if (now_key < utc_key )
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
        x = Model::DB[:forecasts].filter('forecast_date = ? and lat = ? and lon = ?',fd.forecast_date.to_s,fd.lat,fd.lon).to_a
        #x = Model::Forecast.filter('forecast_date = ? and lat = ? and lon =
        #?',fd.forecast_date)
        if x.to_a.length < 1
          raise "X shoulnt be an empty array"
        end

        h_0 = p = nil
        wvper = perpw = persw = nil
        x.each do |forecast|
          
          if forecast[:var_name]== "HTSGW"
            h_0 = forecast[:value]            
          end
          
          #we chose one of these period based if the appear
          #in this seame order

          if forecast[:var_name] == "PERPW" 
            perpw = forecast[:value]
          end                    
          
          if forecast[:var_name] == "PERSW" 
            persw = forecast[:value]
          end                    
          
          if forecast[:var_name] == "WVPER" 
            wvper = forecast[:value]
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
        # puts x
        sample = x.to_a[0]

        Model::DB[:forecasts].insert( 
                                    :var_name=>"SURFZ",
                                    :grib_date=>sample[:grib_date].to_s,
                                    :forecast_date=>sample[:forecast_date].to_s,
                                    :lat => sample[:lat],
                                    :lon => sample[:lon],
                                    :value => surf_size
                                    )
                                    
         Model::DB[:forecasts].insert( 
                                    :var_name=>"SWELLC",
                                    :grib_date=>sample[:grib_date].to_s,
                                    :forecast_date=>sample[:forecast_date].to_s,
                                    :lat => sample[:lat],
                                    :lon => sample[:lon],
                                    :value => swell_class
                                    )
        
        # @log.info("Surf Size for #{surf_entry.forecast_date} = #{surf_size}")      
      end
    

      @log.info("Surf size and swell calculation  process finished")
    end    
    
  end
end
