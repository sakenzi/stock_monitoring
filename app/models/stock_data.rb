require_relative '../routes/stock_controller'

class StockDatum < ActiveRecord::Base
  belongs_to :stock
  after_create_commit :broadcast_stock_update

  private

  def broadcast_stock_update
    puts "Создана новая запись StockDatum: id=#{id}, stock_id=#{stock_id}"
    data = {
      type: "new_stock_data",
      stock_id: stock_id,
      last_price_deal: last_price_deal,
      changed_price: changed_price,
      first_price: first_price,
      max_price: max_price,
      min_price: min_price,
      close_price: close_price,
      quantity_selled: quantity_selled,
      time_update: time_update.iso8601
    }
    StockController.notify_new_stock_data(self)
  end
end