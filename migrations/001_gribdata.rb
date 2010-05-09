
class CreateGribDataTable < Sequel::Migration

    # For the up we want to create the three tables.
  def up
    # Create the books table with a primary key and a title.
    Sequel.datetime_class = DateTime
    create_table :forecasts do
      primary_key :id
      DateTime  :grib_date
      DateTime  :forecast_date
      String :var_name
      String :lat
      String :lon
      Float  :value                  
    end    
  end

  # For the down we want to remove the three tables.
  def down
    drop_table :forecasts
  end

end
