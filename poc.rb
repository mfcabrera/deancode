

require "grib_processor.rb"


def main1
  point1 = Point.new(-33,150)
  point2 = Point.new(-34,151.25)
  
  zone = ForecastZone.new("-33","-35","150","152",6)
  gd = GribDownloader.new(zone,"20090520","settings.yml")
  filename = gd.filename
  gd.download  
  wg = Wgrib2Frontend.new(filename,[point1,point2])
  wg.execute_wgrib2("out.csv")
  
end


main1
