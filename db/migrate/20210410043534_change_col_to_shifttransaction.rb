class ChangeColToShifttransaction < ActiveRecord::Migration[5.0]
  def change
   change_table :shifttransactions do |t|
      t.change :break_time,:string
  end
 end
end
