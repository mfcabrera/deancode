require 'yaml'

desc "Main setup"
task :setup => [:migrate]

yconfig = YAML.load_file("settings.yml")
cstring = yconfig["db"][yconfig["env"]]


desc "DB Migration for the grib data fetcher"
task :migrate  do
  system %{sequel -E  -m migrations/   sqlite://gribdata.db}
  system %{sequel -E  -m migrations/   sqlite://gribdata-test.db}
end

task :migrate_mysql  do
  system %{sequel -E  -m migrations/  "#{cstring}"} 
end

task :migrate_down  do
  system %{sequel -E -M0  -m migrations/   sqlite://gribdata.db}
  system %{sequel -E -M0  -m migrations/   sqlite://gribdata-test.db}
end

task :migrate_mysql_down  do
  system %{sequel -E -M0  -m migrations/  "#{cstring}" }
end



desc "Run spec test"
task :test  do
  sh 'spec -f s spec/forecast_downloader_spec.rb'
end
