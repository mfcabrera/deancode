#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'forecast_downloader'
require 'model/point'
require 'sequel'
require 'yaml'
require 'sequel/extensions/migration'
require 'logger'
include ForecastDownloader


#
# Testing Wgrb2Frontend
#



describe Wgrib2Frontend  do
  before :each do
    @outfile = "spec/outfile.csv"
    @filename="spec/data_-33_152_-35_150_tz6.grib2"
    points = [["-34","151.25"],["-34","152.5"]]
    @wgrib2 = Wgrib2Frontend.new(@filename,points,@outfile)
  end

  
it "should scape the dashes when generating a grep command for the coordinates" do
    @wgrib2.generate_grep_command.should == "egrep \"151.25,\\-34|152.5,\\-34\"" 
 #   puts @wgrib2.generate_grep_command
  end
  
  it "Should filter the locations I want from the wgrib2 command" do
    @wgrib2.generate_command.should == "wgrib2 spec/data_-33_152_-35_150_tz6.grib2 -csv -|  sed -e \"s/[0-9]*:[0-9]*//\" | egrep \"151.25,\\-34|152.5,\\-34\"" 
#"wgrib2 #{@filename} -csv -| egrep \"151.25,\\-34|152.5,\\-34\""  
  end
  
  it "Should output a csv file" do
    
    @wgrib2.execute_wgrib2.should == true
    File.exist?(File.expand_path(@outfile)).should == true
  end
 
end


describe GribDownloader do
  before :each do #top bottom left right
    @date = Date.today.strftime("%Y%m%d")
    
  end
    
  
  it "Should generate the url based in the date and the forecast zone for TZ06" do
    @zone = ForecastZone.new("-33","-35","150","154",6)
    @gd = GribDownloader.new(@zone,@date)    
    
    @gd.url.should ==  "http://nomads.ncep.noaa.gov/cgi-bin/filter_wave.pl?file=nww3.t06z.grib.grib2&lev_surface=on&all_var=on&subregion=&leftlon=150&rightlon=154&toplat=-33&bottomlat=-35&dir=%2Fwave.#{@date}"
    
    
  end
  
  it "Should generate the url based in the date and the forecast zone for  TZ12" do
    @zone = ForecastZone.new("-33","-35","150","154",12)
    @gd = GribDownloader.new(@zone,@date)    
    
    @gd.url.should == "http://nomads.ncep.noaa.gov/cgi-bin/filter_wave.pl?file=nww3.t12z.grib.grib2&lev_surface=on&all_var=on&subregion=&leftlon=150&rightlon=154&toplat=-33&bottomlat=-35&dir=%2Fwave.#{@date}"
  end

  it "Should convert the decimal values of the zone description to integers" do
    @zone = ForecastZone.new("-33.5","-35.0","150","154",6)
    @gd = GribDownloader.new(@zone,@date)    
    
    @gd.url.should ==  "http://nomads.ncep.noaa.gov/cgi-bin/filter_wave.pl?file=nww3.t06z.grib.grib2&lev_surface=on&all_var=on&subregion=&leftlon=150&rightlon=154&toplat=-33&bottomlat=-35&dir=%2Fwave.#{@date}"
    
    
  end

  
  
end

  
describe Model::Point do
    
  
  before :each do
    Model::Point.delete
    Model::Point.insert(:lon=>"150",:lat=>"-33.0",:name=>"ISLAND 1")
    Model::Point.insert(:lon=>"151.25",:lat=>"-34.0",:name=>"ISLAND 2")
  end
  
  it "Should get max and min lat,lon pairs  from the dabase" do
    
    max_lon = Model::Point.max_lon.to_s
    min_lon = Model::Point.min_lon.to_s
    max_lat = Model::Point.max_lat.to_s
    min_lat = Model::Point.min_lat.to_s

#    puts "#{max_lon} -  #{min_lon} - #{max_lat} -  #{min_lat}"
    
    (max_lon == "151.25" and min_lon == "150.0" and max_lat == "-33.0" and  min_lat == "-34.0").should == true
  end
  
  

end


