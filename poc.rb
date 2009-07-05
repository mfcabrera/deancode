require 'forecast_downloader'
require 'model/point'

def main1
  point1 = [-33,150]
  point2 = [-34,151.25]
  
  zone = ForecastZone.new("-32","-35","150","153",6)
  gd = GribDownloader.new(zone,"20090621")
  filename = gd.filename
  gd.download  
  wg = Wgrib2Frontend.new(filename,[point1,point2],"out.csv")
  wg.execute_wgrib2
  gdi = GribDataImporter.new
  gdi.load_from_file("out.csv")
  
end

def main2
  fd = Processor.new
  fd.perform
end


main2
