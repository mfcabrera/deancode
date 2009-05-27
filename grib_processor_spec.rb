#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'grib_processor'



#
# Testing Wgrb2Frontend
#



describe Wgrib2Frontend  do
  before :each do
    @filename="data_-33_152_-35_150_tz6.grib2"
    points = [["151.25","-34"],["152.5","-34"]]
    @wgrib2 = Wgrib2Frontend.new(@filename,points)
  end

  
it "should scape the dashes when generating a grep command for the coordinates" do
    @wgrib2.generate_grep_command.should == "egrep \"151.25,\\-34|152.5,\\-34\"" 
 #   puts @wgrib2.generate_grep_command
  end
  
  it "Should filter the locations I want from the wgrib2 command" do
    @wgrib2.generate_command.should == "wgrib2 #{@filename} -csv -| egrep \"151.25,\\-34|152.5,\\-34\""  
  end
  
  it "Should output a csv file" do
    out_file = "~/outtest.csv"
    @wgrib2.execute_wgrib2(out_file).should == true
    File.exist?(File.expand_path(out_file)).should == true
  end
 
end


describe GribDownloader do
  before :each do #top bottom left right
    @date = "20090520"
    
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
  
  
end

  
 
