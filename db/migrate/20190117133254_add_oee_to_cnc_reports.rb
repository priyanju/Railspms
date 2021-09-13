class AddOeeToCncReports < ActiveRecord::Migration[5.0]
  def change
   add_column :cnc_reports, :availability, :string
   add_column :cnc_reports, :perfomance, :string
   add_column :cnc_reports, :quality, :string
   add_column :cnc_reports, :spindle_load, :string 
   add_column :cnc_reports, :spindle_m_temp, :string
   add_column :cnc_reports, :servo_load, :json
   add_column :cnc_reports, :servo_m_temp, :json
   add_column :cnc_reports, :puls_code, :json
   add_column :cnc_reports, :test_code, :string
  end
end
