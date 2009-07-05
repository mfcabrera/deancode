
class CreatePointsDataTable < Sequel::Migration

    # For the up we want to create the three tables.
  def up
    # Create the books table with a primary key and a title.
    Sequel.datetime_class = DateTime    
    create_table :forecast_points do
      primary_key :id
      Float  :lat
      Float  :lon
      String :name
    end    
  end
  
  # For the down we want to remove the three tables.
  def down
    drop_table :forecast_points
  end

end
