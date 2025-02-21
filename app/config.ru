require './app'
require 'tzinfo'
require 'sidekiq/web'
require 'dotenv/load'

TZInfo::DataSource.set(:ruby)
Sidekiq.configure_server do |config|
  ENV['TZ'] ||= 'Asia/Almaty' 
end

use Rack::Session::Cookie, secret: SecureRandom.hex(32), same_site: true, max_age: 86400

Sidekiq::Web.use Rack::Auth::Basic, "Protected Area" do |username, password|
  username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
end

map '/sidekiq' do
  run Sidekiq::Web
end

run MyApp
