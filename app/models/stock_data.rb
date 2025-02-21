class StockDatum < ActiveRecord::Base
    belongs_to :stock
  
    validates :last_price_deal, :time_update, presence: true
    validates :first_price, :max_price, :min_price, :close_price, :quantity_selled, numericality: true
    validates :last_price_deal, :first_price, :max_price, :min_price, :close_price, numericality: { greater_than_or_equal_to: 0 }
  end
  