require 'sinatra/base'
require 'sinatra/json'
require_relative '../models/stock_data'
require_relative '../models/stock'

class StockController < Sinatra::Base
    get '/stocks' do
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = 20
        offset = (page - 1) * per_page

        stocks = Stock.includes(:stock_data)
                      .limit(per_page)
                      .offset(offset)
        
        stocks_data = stocks.map do |stock|
            last_stock_data = stock.stock_data.order(time_update: :desc).limit(1).first
            
            {
                id: stock.id,
                stock_name: stock.stock_name,
                stock_data: last_stock_data ? {
                    last_price_deal: last_stock_data.last_price_deal,
                    changed_price: last_stock_data.changed_price,
                    first_price: last_stock_data.first_price,
                    max_price: last_stock_data.max_price,
                    min_price: last_stock_data.min_price,
                    close_price: last_stock_data.close_price,
                    quantity_selled: last_stock_data.quantity_selled,
                    time_update: last_stock_data.time_update
                } : nil
            }
        end

        content_type :json
        { stocks: stocks_data, page: page }.to_json
    end

    get '/stocks/:id' do
        stock = Stock.includes(:stock_data).find_by(id: params[:id])

        if stock.nil?
            halt 404, { error: "Stock not found" }.to_json
        end

        last_stock_data = stock.stock_data.order(time_update: :desc).limit(1).first
        
        stock_data = {
            id: stock.id,
            stock_name: stock.stock_name,
            stock_data: last_stock_data ? {
                last_price_deal: last_stock_data.last_price_deal,
                changed_price: last_stock_data.changed_price,
                first_price: last_stock_data.first_price,
                max_price: last_stock_data.max_price,
                min_price: last_stock_data.min_price,
                close_price: last_stock_data.close_price,
                quantity_selled: last_stock_data.quantity_selled,
                time_update: last_stock_data.time_update
            } : nil
        }

        content_type :json
        stock_data.to_json
    end
end
