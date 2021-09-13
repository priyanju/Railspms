class CreateMacroSignals < ActiveRecord::Migration[5.0]
  def change
    create_table :macro_signals do |t|
      t.datetime :update_date
      t.datetime :end_date
      t.integer :time_stamp
      t.string :signal
      t.float :value
      t.references :machine, foreign_key: true

      t.timestamps
    end
  end
end
