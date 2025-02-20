require 'active_record'

class StockData <ActiveRecord::Base
    belongs_to :stock

    validates :last_price_deal, :time_update, presence: true
end