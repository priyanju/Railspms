class AddColToShifttransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :shifttransactions, :break_time, :integer
  end
end
