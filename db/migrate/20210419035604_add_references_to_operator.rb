class AddReferencesToOperator < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :created_by, :string
#    add_reference :operators, :role, foreign_key: true
#    t.references :created_by, foreign_key: { to_table: :users }
#      add_referencE :created_by, foreign_key: { to_table: :roles }
#     add_reference :operators, :created_by, foreign_key: { to_table: :roles }
  end
end
