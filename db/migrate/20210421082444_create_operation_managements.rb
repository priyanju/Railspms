class CreateOperationManagements < ActiveRecord::Migration[5.0]
  def change
    create_table :operation_managements do |t|
      t.string :operation_name
      t.integer :operation_id
      t.integer :std_cycle_time
      t.integer :load_unload_time
      t.integer :setup_time
      t.string :created_by
      t.integer :status
      t.integer :part_per_cycle
      t.datetime :deleted_at
      t.references :part_configuration, foreign_key: true
      t.references :process_plan, foreign_key: true
      t.references :tenant, foreign_key: true

      t.timestamps
    end
  end
end
