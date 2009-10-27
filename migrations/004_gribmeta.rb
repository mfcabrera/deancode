
class CreateGribMetaTable < Sequel::Migration

  # For the up we want to create the three tables.
  def up

    Sequel.datetime_class = DateTime    
    create_table :grib_meta do
      primary_key :id
      DateTime  :grib_date
      String    :noaa_filename      
      String :model_run
    end    
  end
  

  def down
    drop_table :grib_meta
  end
  
end
