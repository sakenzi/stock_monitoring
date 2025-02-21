require 'sinatra'
require 'sinatra/activerecord'
require 'sidekiq-cron'
require 'yaml'
require_relative 'routes/sidekiq_controller'
require_relative 'routes/stock_controller'

config = YAML.load_file('sidekiq.yml')
config = config.deep_transform_keys(&:to_s) if config.is_a?(Hash) && config.respond_to?(:deep_transform_keys)

Sidekiq::Cron::Job.load_from_hash(config["schedule"])

set :database_file, File.expand_path('database.yml', __dir__)

class MyApp < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  get '/' do
    "Stock Monitoring Service is running!"
  end

  use SidekiqController
  use StockController
end
  

run MyApp if __FILE__ == $0
