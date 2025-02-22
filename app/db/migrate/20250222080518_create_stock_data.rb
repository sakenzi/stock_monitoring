class CreateStockData < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_data do |t|
      t.references :stock, foreign_key: true, null: false
      t.references :stock_country, foreign_key: true, null: false
      t.decimal :last_price_deal, precision: 10, scale: 2, null: false
      t.decimal :changed_price, precision: 10, scale: 2
      t.decimal :first_price, precision: 10, scale: 2
      t.decimal :max_price, precision: 10, scale: 2
      t.decimal :min_price, precision: 10, scale: 2
      t.decimal :close_price, precision: 10, scale: 2
      t.bigint :quantity_selled, null: false, default: 0
      t.datetime :time_update, null: false
      t.timestamps
    end
  end
end