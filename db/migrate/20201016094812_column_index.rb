class ColumnIndex < ActiveRecord::Migration[5.0]
  def change
  	add_index :machine_logs, :created_at
    add_index :machine_daily_logs, :created_at
    
  end
end
