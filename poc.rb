

require "grib_processor.rb"
include ForecastDownloader

def main1
  point1 = [-33,150]
  point2 = [-34,151.25]
  
  zone = ForecastZone.new("-32","-35","150","153",6)
  gd = GribDownloader.new(zone,"20090621","settings.yml")
  filename = gd.filename
  gd.download  
  wg = Wgrib2Frontend.new(filename,[point1,point2],"out.csv")
  wg.execute_wgrib2
  gdi = GribDataImporter.new
  gdi.load_from_file("out.csv")
  
end


main1
