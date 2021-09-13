class AddColToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :role_name, :string
  end
end
