class CreateHmiMachineDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :hmi_machine_details do |t|
      t.date :date
      t.integer :shift_no
      t.json :data 
      t.belongs_to :operator, foreign_key: true
      t.belongs_to :machine, foreign_key: true
      t.belongs_to :tenant, foreign_key: true

      t.timestamps
    end
  end
end
