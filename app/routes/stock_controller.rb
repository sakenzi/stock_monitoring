require 'sinatra/base'
require 'sinatra/json'
require 'em-websocket'
require 'eventmachine'
require_relative '../models/stock_data'
require_relative '../models/stock'

class StockController < Sinatra::Base
  set :server, 'puma'
  set :sockets, []

  get '/stocks' do
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = 20
    offset = (page - 1) * per_page

    stocks = Stock.includes(:stock_data)
                  .limit(per_page)
                  .offset(offset)

    stocks_data = stocks.map do |stock|
      {
        id: stock.id,
        stock_name: stock.stock_name,
        stock_data: stock.stock_data.order(time_update: :desc).first&.slice(
          :last_price_deal, :changed_price, :first_price,
          :max_price, :min_price, :close_price, :quantity_selled, :time_update
        )
      }
    end

    json stocks: stocks_data, page: page
  end

  get '/websocket' do
    halt 400, "Используйте WebSocket-соединение на ws://localhost:3001"
  end

  get '/stock-api' do
    halt 400, "Используйте WebSocket-соединение на ws://localhost:3001"
  end

  def self.notify_new_stock_data(stock_datum)
    data = {
      type: "new_stock_data",
      stock_id: stock_datum.stock_id,
      data: stock_datum.attributes
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
              ws.send({ type: "latest_data", data: latest_data&.attributes }.to_json)
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