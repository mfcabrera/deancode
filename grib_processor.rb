#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

# Copyright (c) 2009 Miguel Cabrera
 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWA



require 'rubygems'
require 'ccsv'
require 'yaml'
require 'curl'
require 'logger' 
require 'singleton'



class  MyLogger
  include Singleton
  
  #Move this were appropiate
  def initialize
    @yconfig = YAML.load_file("settings.yml")
    @log_file =  @yconfig["log_file"]
    if @log_file == "STDOUT"
      @logger = Logger.new(STDOUT, 'weekly')
    else
      @logger = Logger.new(@log_file, 'weekly')
    end
    @logger.level = Logger::INFO   
  end
  
  def level=(lv)
    if not ["info","debug","trace","error"].include?(lv)
      lv="info"
    end
    @logger.level = eval("Logger::#{lv.upcase}")    
  end
  
  #I know there is a more elegant form of doing this
  #But whatever... xD
  
  def debug(msg)
    @logger.debug(msg)
  end

  def info(msg)
    @logger.info(msg)
  end

  def error(msg)
    @logger.error(msg)
  end 
end



class String
  def scape_dash
    self.sub("-","\\-")
  end
end

#  Ccsv.foreach(file) do |values|
#   puts values.to_s
#  end

file = "datatest.csv"


class Wgrib2Frontend
  #This class is a front-end for Wgrib2
  #and helps to filter out information from
  #grib2 files  
  
  def initialize(filename,points)
    @points = points
    @filename = filename
    @log = MyLogger.instance
    
  end

  
  def generate_command
    yconfig = YAML.load_file("settings.yml")
    exe = "#{yconfig['wgrib_path']}/#{yconfig['wgrib_name']}"
    raise "wgrib path does not exists - check settings.yml" if not File.exist?(exe)
    command = "wgrib2 #{@filename} -csv -| "    
    command << generate_grep_command       
  end
  

  def execute_wgrib2(out_filename)
    cmd = generate_command << " > #{out_filename}"
    @log.info("Executing: #{cmd}")

    #FIXME: Use Open4 to get the data and save it directly
    unless system(cmd) 
      raise "Error creating .csv file" 
    end

    true             
  end
  
  def generate_grep_command
    
    egrep_line = "egrep \"" 
    
    size = @points.size
    ii = 1
    @points.each do |point|
      egrep_line << "#{point[0].to_s.scape_dash},#{point[1].to_s.scape_dash}" 
      egrep_line << "|" if ii < size
      ii = ii + 1
    end
    
    egrep_line << "\""
    
  end    
end


class Point
  attr_reader :lon,:lat 
  
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
  
  def initialize(lat,lon)
    validate_params(lat,lon)
    @lon,@lat = lon,lat        
  end
end
  
  class ForecastZone
  attr_accessor :tlat,:blat,:rlon,:llon
  attr_accessor :utc_offset #00,06,12,18
  
  def initialize(tlat,blat,llon,rlon,utc_offset=0)
    (@tlat,@blat,@rlon,@llon) = tlat,blat,rlon,llon    
    if ![0,6,12,18].include?(utc_offset)
      raise "Invalid UTC offset"
    end
    @utc_offset = utc_offset
  end
  
  def points=(pts)
    pts.each do |p|
        if not ((llon..rlon).include?(p.lon))     
          raise ("Invalid point for Forecast zone")
        end
        #TODO: Write validation code for latitude
      end
  end  
end

class GribDownloader
  
  attr_reader :url
  attr_reader :filename
  
  
  #date in format YYYYMMDD
  def initialize(zone,date,config_file="settings.yml")
    @date = date
    @zone = zone
    @filename =  "data_#{@zone.tlat}_#{@zone.rlon}_#{@zone.blat}_#{@zone.llon}_tz#{@zone.utc_offset}.grib2"
    @yconfig = YAML.load_file(config_file)
    @urlroot =  @yconfig["urlroot"]    
    loglevel  = @yconfig["log_level"]
    logfile = @yconfig["log_file"]
    @log = MyLogger.instance
    @log.level = loglevel
    @url = generate_url    
    
    @log.debug("Filename: #{filename}")

  end

  

  def download    
    
    # url = "http://xue.unalmed.edu.co/~mfcabrera/ahijada.jpg" 
    
    c = Curl::Easy.new(@url) do |curl|
        curl.verbose = true
      end
    
    
    @log.info("Dowloading #{@url}")
    c.perform 
    
    
    if c.response_code != 200
      @log.error("An error ocurred while downloading the grib file")
      @log.error("The response code was #{c.response_code}")
      @log.error("The url was: {@url}")      
      raise "Error downloading the grib file"
    end
    
    # Something went wrong if the downloaded bytes is not the same 
     
    if c.downloaded_content_length > 0 and c.downloaded_content_length !=  c.downloaded_bytes
      #TODO: downloaded bytes don't match.
      @log.error "An error ocurred while downloading the grib file"
      @log.error "The sizes does not match"
      raise "Error downloading the grib file"
      
    end
    
    
    @log.info "ALL - OK Saving file to disk"
    File.open(@filename,"w") { |o| o.write(c.body_str) } 
    @log.info "File saved correctly"
    
  end
  
  private
  def generate_url
    
    @log.info("Generating URL based on Zone definition")
    utc = @zone.utc_offset > 10? @zone.utc_offset : "0#{@zone.utc_offset}"
        
    rlon = @zone.rlon.to_i > 0? @zone.rlon.to_i: @zone.rlon.to_i + 360
    llon = @zone.llon.to_i > 0? @zone.llon.to_i: @zone.llon.to_i + 360
    
    params ="?file=nww3.t#{utc}z.grib.grib2&lev_surface=on&all_var=on&subregion=&leftlon=#{llon}&rightlon=#{rlon}&toplat=#{@zone.tlat}&bottomlat=#{@zone.blat}&dir=%2Fwave.#{@date}"
    @log.debug("Parameters for grib filter #{params}")
    url = "#{@urlroot}#{params}"
    @log.debug("URL generated: #{url}")
    url
    
  end    
end




class WaveCsvReader
  # This class reads the CSV files generated by wgrib2 program and  
  # based on a list of lat lot points filters the data that and insert them
  # in database
  
  #  CSV::Reader.parse(File.open('datatest.csv', 'r')) do |row|
  #    puts row
  #   break if !row[0].is_null && row[0].data == 'stop'
  # end
  
end


