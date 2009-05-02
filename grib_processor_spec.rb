#!/usr/bin/ruby

require 'grib_processor'



#
# Testing Wgrb2Frontend
#



describe Wgrib2Frontend  do
  before :each do
    @filename="/home/mfcabrera/code/nww3.t00z.grib.grib2"
    points = [["165","-77"],["40","-75"]]
    @wgrib2 = Wgrib2Frontend.new(@filename,points)
  end

  
it "should scape the dashes when generating a grep command for the coordinates" do
    @wgrib2.generate_grep_command.should == "egrep \"165,\\-77|40,\\-75\"" 
 #   puts @wgrib2.generate_grep_command
  end
  
  it "Should filter the locations I want from the wgrib2 command" do
    @wgrib2.generate_command.should == "wgrib2 #{@filename} -csv -| egrep \"165,\\-77|40,\\-75\""
  end
  
  it "Should output a csv file" do
    out_file = "~/outtest.csv"
    @wgrib2.execute_wgrib2(out_file).should == true
    File.exist?(File.expand_path(out_file)).should == true
  end

  
end
