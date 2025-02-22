require 'sinatra/base'
require 'sinatra/json'
require 'em-websocket'
require 'eventmachine'
require_relative '../models/stock_data'
require_relative '../models/stock'
require_relative '../models/stock_country'

class StockController < Sinatra::Base
  set :server, 'puma'
  set :sockets, []

  get '/stocks' do
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 20
    offset = (page - 1) * per_page

    stocks = Stock.includes(stock_data: :stock_country)
                  .limit(per_page)
                  .offset(offset)

    stocks_data = stocks.map do |stock|
      latest_data = stock.stock_data.order(time_update: :desc).first
      {
        id: stock.id,
        stock_name: stock.stock_name,
        country_name: latest_data&.stock_country&.country_name,
        stock_data: latest_data&.slice(
          :last_price_deal, :changed_price, :first_price,
          :max_price, :min_price, :close_price, :quantity_selled, :time_update
        )
      }
    end

    json stocks: stocks_data, page: page
  end

  get '/stocks/:id' do
    stock = Stock.find_by(id: params[:id])
    if stock
      latest_data = stock.stock_data.order(time_update: :desc).first
      if latest_data
        response = {
          stock_name: stock.stock_name,
          stock_id: stock.id,
          country_name: latest_data.stock_country&.country_name,
          data: latest_data.attributes
        }
        json response
      else
        halt 404, json({ error: "Данные для акции не найдены" })
      end
    else
      halt 404, json({ error: "Акция не найдена" })
    end
  end

  get '/stocks/by_country/:country_id' do
    country_id = params[:country_id].to_i
    limit = params[:limit]&.to_i || 10  

    if country_id > 0 && limit > 0
      country = StockCountry.find_by(id: country_id)
      if country
        stock_data = StockDatum.where(stock_country_id: country_id)
                               .order(time_update: :desc)
                               .limit(limit)
                               .includes(:stock, :stock_country)

        if stock_data.any?
          response = {
            country_name: country.country_name,
            stocks: stock_data.map do |datum|
              {
                stock_name: datum.stock&.stock_name,
                stock_id: datum.stock_id,
                last_price_deal: datum.last_price_deal,
                changed_price: datum.changed_price,
                first_price: datum.first_price,
                max_price: datum.max_price,
                min_price: datum.min_price,
                close_price: datum.close_price,
                quantity_selled: datum.quantity_selled,
                time_update: datum.time_update.iso8601
              }
            end
          }
          json response
        else
          halt 404, json({ error: "Данные для страны не найдены" })
        end
      else
        halt 404, json({ error: "Страна не найдена" })
      end
    else
      halt 400, json({ error: "Укажите корректные country_id и limit" })
    end
  end

  get '/websocket' do
    halt 400, "Используйте WebSocket-соединение на ws://localhost:3001"
  end

  get '/stock-api' do
    halt 400, "Используйте WebSocket-соединение на ws://localhost:3001"
  end

  def self.notify_new_stock_data(stock_datum)
    stock = Stock.find_by(id: stock_datum.stock_id)
    stock_name = stock&.stock_name || "Unknown Stock"
    country_name = stock_datum.stock_country&.country_name || "Unknown Country"

    data = {
      type: "new_stock_data",
      stock_name: stock_name,
      stock_id: stock_datum.stock_id,
      country_name: country_name,
      data: {
        id: stock_datum.id,
        stock_id: stock_datum.stock_id,
        last_price_deal: stock_datum.last_price_deal,
        changed_price: stock_datum.changed_price,
        first_price: stock_datum.first_price,
        max_price: stock_datum.max_price,
        min_price: stock_datum.min_price,
        close_price: stock_datum.close_price,
        quantity_selled: stock_datum.quantity_selled,
        time_update: stock_datum.time_update.iso8601,
        created_at: stock_datum.created_at.iso8601,
        updated_at: stock_datum.updated_at.iso8601
      }
    }
    puts "Количество подключённых клиентов: #{settings.sockets.size}"
    settings.sockets.each do |socket|
      puts "Отправка данных клиенту: #{data}"
      socket.send(data.to_json)
    end
    puts "Отправлено уведомление о новом stock_data: #{data}"
  end

  private

  def broadcast_to_all(data)
    puts "Вещание данных: #{data}"
    settings.sockets.each do |socket|
      socket.send(data.to_json)
    end
  end
end

Thread.new do
  puts "Запускаем EventMachine для WebSocket..."
  EventMachine.run do
    puts "EventMachine запущен, настройка WebSocket на порту 3001"
    EventMachine::WebSocket.start(host: '0.0.0.0', port: 3001) do |ws|
      ws.onopen do |handshake|
        puts "Новое WebSocket-соединение установлено (#{StockController.settings.sockets.size} клиентов)"
        StockController.settings.sockets << ws
        ws.send({ type: "welcome", message: "Подключено к WebSocket акций" }.to_json)
      end

      ws.onmessage do |msg|
        begin
          data = JSON.parse(msg)
          if data["action"] == "fetch_latest"
            stock = Stock.find_by(id: data["stock_id"])
            if stock
              latest_data = stock.stock_data.order(time_update: :desc).first
              if latest_data
                response = {
                  type: "latest_data",
                  stock_name: stock.stock_name,
                  country_name: latest_data.stock_country&.country_name,
                  data: latest_data.attributes
                }
                ws.send(response.to_json)
              else
                ws.send({ type: "error", message: "Данные для акции не найдены" }.to_json)
              end
            else
              ws.send({ type: "error", message: "Акция не найдена" }.to_json)
            end
          elsif data["command"] != "ping"
            StockController.new.send(:broadcast_to_all, data)
          end
        rescue JSON::ParserError
          ws.send({ type: "error", message: "Неверный формат сообщения" }.to_json)
        end
      end

      ws.onclose do
        puts "WebSocket-соединение закрыто (#{StockController.settings.sockets.size - 1} клиентов осталось)"
        StockController.settings.sockets.delete(ws)
      end
    end
  end
end