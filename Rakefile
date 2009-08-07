
desc "Main setup"
task :setup => [:migrate]

desc "DB Migration for the grib data fetcher"
task :migrate  do
  system %{sequel -E  -m migrations/   sqlite://gribdata.db}
  system %{sequel -E  -m migrations/   sqlite://gribdata-test.db}
end

task :migrate_down  do
  system %{sequel -E -M0  -m migrations/   sqlite://gribdata.db}
  system %{sequel -E -M0  -m migrations/   sqlite://gribdata-test.db}
end


desc "Run spec test"
task :test  do
  sh 'spec -f s spec/forecast_downloader_spec.rb'
end
