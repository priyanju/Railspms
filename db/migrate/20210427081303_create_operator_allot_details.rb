class CreateOperatorAllotDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_allot_details do |t|
      t.references :operation_management, foreign_key: true
      t.references :operator_allocation, foreign_key: true
      t.references :operator, foreign_key: true
      t.datetime :end_time
      t.datetime :start_time

      t.timestamps
    end
  end
end
