class CreatePartConfigurations < ActiveRecord::Migration[5.0]
  def change
    create_table :part_configurations do |t|
      t.string :part_number
      t.string :part_name
      t.string :customer_name
      t.integer :status
      t.string :part_description
      t.string :created_by
      t.datetime :deleted_at
      t.references :tenant, foreign_key: true
      
      t.timestamps
    end
  end
end
