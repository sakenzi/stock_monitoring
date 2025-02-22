class CreateStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :stocks do |t|
      t.string :stock_name, null: false
      t.timestamps
    end
    add_index :stocks, :stock_name, unique: true
  end
end