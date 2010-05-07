
#We make inherit from SequelModel directly.
require 'rubygems'
require 'yaml'
require 'sequel'
require 'forecast_downloader'
load 'model/model.rb'
include ForecastDownloader

module ForecastDownloader
  module Model

    class Forecast  < Sequel::Model(:forecasts)      
    include ForecastDownloader::Model

    end
    
  end
  
end
