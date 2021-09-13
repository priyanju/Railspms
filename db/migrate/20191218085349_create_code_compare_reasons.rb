class CreateCodeCompareReasons < ActiveRecord::Migration[5.0]
  def change
    create_table :code_compare_reasons do |t|
      t.references :user, foreign_key: true
      t.references :machine, foreign_key: true
      t.string :description
      t.integer :current_location
      t.boolean :status
      t.string :file_path

      t.timestamps
    end
  end
end
