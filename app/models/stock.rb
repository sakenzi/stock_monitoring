require 'active_record'

class Stock < ActiveRecord::Base
    has_many :stock_data, dependent: :destroy
    validates :stock_name, presence: true, uniqueness: true
end