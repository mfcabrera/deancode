
class CreateGribMetaTable < Sequel::Migration

  # For the up we want to create the three tables.
  def up
    # Create the books table with a primary key and a title.
    Sequel.datetime_class = DateTime    
    create_table :grib_meta do
      primary_key :id
      DateTime  :grib_date
      String    :noaa_filename      
    end    
  end
  
  # For the down we want to remove the three tables.
  def down
    drop_table :grib_meta
  end
  
end
