class RemoveColumnOperatorAllocation < ActiveRecord::Migration[5.0]
  def change
      remove_column :operator_allocations, :from_date, :date
      remove_column :operator_allocations, :to_date, :date
	add_column :operator_allocations, :date, :datetime
	add_column :operator_allocations, :created_by, :string
  end
end
