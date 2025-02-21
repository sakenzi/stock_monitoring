require 'sinatra/base'
require 'sinatra/json'
require 'sidekiq'
require_relative '../workers/parser_workers'

class SidekiqController < Sinatra::Base
  before do
    content_type :json
  end

  get '/start_parser' do
    begin
      status 200
      ParserWorker.perform_async
      json(message: 'Парсер запущен!')
    rescue => e
      status 500
      json(error: "Ошибка запуска парсера: #{e.message}")
    end
  end
end
