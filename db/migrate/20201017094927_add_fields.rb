class AddFields < ActiveRecord::Migration[5.0]
  def change
  	add_column :machines, :alarm_setting, :json
  	add_column :machines, :axis_setting, :json
  	add_column :machines, :dis_min, :integer, :default => 10
  	add_column :machines, :dis_sec, :integer, :default => 0
  	add_column :machines, :dis_tot, :integer, :default => 600
  	add_reference :shifttransactions, :tenant, index: true

  end
end

