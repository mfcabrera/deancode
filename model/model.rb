require 'rubygems'
require 'yaml'
require 'sequel'
require 'forecast_downloader'
include ForecastDownloader

module ForecastDownloader
  module Model
    Sequel.datetime_class = DateTime
    config = YAML.load_file(File.dirname(__FILE__)+ "/../settings.yml")
    CONNECTION_STRING = config["db"][config["env"]]
    ::MyLogger.instance.debug("Using db connection #{CONNECTION_STRING}") 
    DB = Sequel.connect(CONNECTION_STRING)
  end
end
