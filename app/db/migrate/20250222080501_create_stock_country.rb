class CreateStockCountry < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_countries do |t|
      t.string :country_name, null: false
      t.timestamps
    end
    add_index :stock_countries, :country_name, unique: true
  end
end