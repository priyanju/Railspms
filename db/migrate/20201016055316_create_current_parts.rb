class CreateCurrentParts < ActiveRecord::Migration[5.0]
  def change
    create_table :current_parts do |t|
      t.date :date
      t.string :shift_no
      t.string :part
      t.string :program_number
      t.integer :cycle_time
      t.integer :cutting_time
      t.string :cycle_st_to_st
      t.string :cycle_stop_to_stop
      t.datetime :time
      t.datetime :part_start_time
      t.datetime :part_end_time
      t.datetime :cycle_start
      t.integer :status
      t.boolean :is_active
      t.datetime :deleted_at
      t.references :shifttransaction, foreign_key: true
      t.references :machine, foreign_key: true

      t.timestamps
    end
  end
end
