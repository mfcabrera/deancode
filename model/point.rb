
#We make inherit from SequelModel directly.
module ForecastDownloader::Model
  class Point  
    
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
    
    def initialize(lat,lon,name="")
      validate_params(lat,lon)
      @lon,@lat,@name = lon,lat,name        
    end
  end
  
end

