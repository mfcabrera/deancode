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
require 'yaml'
require 'curl'
require 'logger' 
require 'singleton'
require 'sequel'
require 'faster_csv'
require 'date'


#Some Monkey Patches for String
class String
  def scape_dash
    self.sub("-","\\-")
  end


  def is_int?
    self =~ /^[-+]?[0-9]*$/
  end
end


#Some patches for Time class
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end



module ForecastDownloader

SETTINGS_FILE="settings.yml"

class MyLogger
  include Singleton
  
  #Move this were appropiate
  def initialize
    
    yconfig =  YAML.load_file(SETTINGS_FILE)
    @log_file =  yconfig["log_file"]
    if @log_file == "STDOUT"
      @logger = Logger.new(STDOUT, 'weekly')
    else
      @logger = Logger.new(@log_file, 'weekly')
    end
    @logger.level = Logger::INFO   
  
  end
  
  def level=(lv)
    
    lv.upcase!
    if not ["INFO","DEBUG","TRACE","ERROR"].include?(lv)
      lv="INFO"
    end
    @logger.level = eval("Logger::#{lv}")    
  end
  
  
  def method_missing(sym, *args, &block)
    @logger.send sym, *args 
  end
  
end


#  Ccsv.foreach(file) do |values|
#   puts values.to_s
#  end


class Wgrib2Frontend
  #This class is a front-end for Wgrib2
  #and helps to filter out information from
  #grib2 files  
  
  def initialize(filename,points,outfile)
    @points = points
    @filename = filename
    @log = MyLogger.instance
    @outfile = outfile
    
  end

  
  def generate_command(config={})
    yconfig =  YAML.load_file(SETTINGS_FILE).merge!(config)
    exe = "#{yconfig['wgrib_path']}/#{yconfig['wgrib_name']}"
    raise "wgrib path does not exists - check settings.yml" if not File.exist?(exe)
    command = "wgrib2 #{@filename} -csv -| "  + " sed -e \"s\/[0-9]*:[0-9]*//\" | "  
    command << generate_grep_command       
  end
  

  def execute_wgrib2
    cmd = generate_command << " > #{@outfile}"
    @log.info("Executing: #{cmd}")
    

    #FIXME: Use Open4 to get the  data and save it directly
    #Or use a more elegant way
    unless system(cmd) 
      raise " Error creating .csv file - No output/Bad Point" 
    end

    true             
  end

  def format_number(num)
    fn = num.to_f
    int = num.to_i
    res = fn-int
    if res > 0
      fn
    else
      int
    end    
  end
  
  def generate_grep_command
    
    egrep_line = "egrep \"" 
    
    size = @points.size
    ii = 1
    @points.each do |point|
        # If the numbers is a float but is also a integer, example 34.0. We
        # should remove the trailing .0
        point0 = format_number(point[0])
        point1 = format_number(point[1])       
        
        egrep_line << "#{point1.to_s.scape_dash},#{point0.to_s.scape_dash}" 
        egrep_line << "|" if ii < size
        ii = ii + 1
      end
    
    egrep_line << "\""
    
  end    
end


class ForecastZone
  attr_accessor :tlat,:blat,:rlon,:llon
  attr_accessor :utc_offset #00,06,12,18
  
  def initialize(tlat,blat,llon,rlon,utc_offset=0)
    utc_offset = utc_offset.to_i
    (@tlat,@blat,@rlon,@llon) = tlat.to_i,blat.to_i,rlon.to_i,llon.to_i
    if not [0,6,12,18].include?(utc_offset)
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
  def initialize(zone,date,config={})
    @date = date
    @zone = zone
    @filename =  "data_#{@zone.tlat}_#{@zone.rlon}_#{@zone.blat}_#{@zone.llon}_tz#{@zone.utc_offset}.grib2"
    yconfig = YAML.load_file(SETTINGS_FILE).merge!(config) 
    @urlroot =  yconfig["urlroot"]    
    loglevel  = yconfig["log_level"]
    logfile = yconfig["log_file"]
    @log = MyLogger.instance
    @log.level = loglevel
    @url = generate_url 
    @log.debug("URL Generarted: {@url}")
    
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
      @log.error("The url was: #{@url}")      
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
    @log.debug("Generating url for UTC #{@zone.utc_offset}")
    
        
    rlon = @zone.rlon.to_i > 0? @zone.rlon.to_i: @zone.rlon.to_i + 360
    llon = @zone.llon.to_i > 0? @zone.llon.to_i: @zone.llon.to_i + 360
    
    params ="?file=nww3.t#{utc}z.grib.grib2&lev_surface=on&all_var=on&subregion=&leftlon=#{llon}&rightlon=#{rlon}&toplat=#{@zone.tlat}&bottomlat=#{@zone.blat}&dir=%2Fwave.#{@date}"
    @log.debug("Parameters for grib filter #{params}")
    url = "#{@urlroot}#{params}"
    @log.debug("URL generated: #{url}")
    url
    
  end    
end





  
  class GribDataImporter
    # This class  Imports data from CSV files into
    # The database
    
    def initialize
      @log = MyLogger.instance
      Sequel.datetime_class = DateTime
      yconfig =  YAML.load_file(SETTINGS_FILE)
      @DB =  Sequel.connect(yconfig["db"]["test"],:logger => Logger.new(yconfig["db_log_file"]))           
      
      
      @dataset = @DB[:forecasts]            
    end
      #Read from a CSV file
    def load_from_file(file)
      @log.info("Deleting previous forecasts from forecast table")
      @dataset.delete
      @log.info("Loading new forecasts from file: #{file}")
      FasterCSV.foreach(file, :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|
        insert_forecast row
      end    
      @log.info("File loaded correctly. #{@dataset.count} forecasts inserted." )
    end
    
    def insert_forecast(data)    
      
      @dataset.insert(:grib_date => DateTime.parse(data[0].gsub(/:[01][0268]/,"")).to_s,
                      :forecast_date => DateTime.parse(data[1]).to_s,
                      :var_name => data[2],
                      :lat => data[5],
                      :lon => data[4],
                      :value => data[6]
                     )
    end
    
    
  end
    

  
  
  
end


