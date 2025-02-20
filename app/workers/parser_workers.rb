require 'sidekiq'
require_relative '../parsing/stock_pars'

class ParserWorker
  include Sidekiq::Worker

  def perform
    puts "Запуск парсера: #{Time.now}"
    StockParser.run
  rescue StandardError => e
    puts "Ошибка при выполнении парсера: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
