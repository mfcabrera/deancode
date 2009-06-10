
desc "Main setup"
task :setup => [:migrate]

desc "DB Migration for the grib data fetcher"
task :migrate  do
  system %{sequel -E  -m migrations/   sqlite://gribdata.db}
end

