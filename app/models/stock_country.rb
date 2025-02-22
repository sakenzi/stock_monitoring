class StockCountry < ActiveRecord::Base
    has_many :stock_data, dependent: :destroy
    validates :country_name, presence: true, uniqueness: true
  end