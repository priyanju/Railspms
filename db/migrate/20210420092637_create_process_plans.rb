class CreateProcessPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :process_plans do |t|
      t.string :plan_number
      t.string :plan_name
      t.string :part_number
      t.string :plan_description
      t.string :created_by
      t.integer :status
      t.datetime :deleted_at
      t.references :tenant, foreign_key: true
      t.references :part_configuration, foreign_key: true

      t.timestamps
    end
  end
end
