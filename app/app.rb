require 'sinatra'
require 'sinatra/activerecord'
require 'sidekiq'
require_relative 'workers/parser_workers'

set :database_file, File.expand_path('database.yml', __dir__)

class MyApp < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  get '/' do
    "Stock Monitoring Service is running!"
  end

  get '/start_parser' do
    ParserWorker.perform_async
    "Парсер запущен!"
  end

  run! if app_file == $0
end
