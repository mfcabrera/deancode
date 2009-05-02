#!/usr/bin/ruby -w 

require 'rubygems'
require 'curb'

class GDTest
  
  def download_grib(file_name="wepat03z.grib.jpg")
    url = "http://xue.unalmed.edu.co/~mfcabrera/ahijada.jpg" 
    c = Curl::Easy.new(url) do |curl|
    curl.verbose = true
    end
    c.perform 
    
    if c.response_code != 200
      #TODO: Log Here with the Logger.
      puts "An error ocurred while downloading the grib file"
      puts "The response code was #{c.response_code}"
      puts "The url was: {@url}"      
      raise "Error downloading the grib file"
    end
    
    # Something went wrong if the downloaded bytes is not the same 
    
    if c.downloaded_content_length > 0 and c.downloaded_content_length !=  c.downloaded_bytes
      #TODO: downloaded bytes don't match.
      puts "An error ocurred while downloading the grib file"
      puts "The sizes does not match"
      raise "Error downloading the grib file"
      
    end
    
    
    puts "Saving file to disk"
    File.open(file_name,"w") { |o| o.write(c.body_str) } 
    
  end
end


gdt = GDTest.new

gdt.download_grib
