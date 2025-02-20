require './app'
require 'sidekiq/web'

Sidekiq::Web.use Rack::Auth::Basic, "Protected Area" do |username, password|
  username == 'admin' && password == 'secret'
end

map '/sidekiq' do
  run Sidekiq::Web
end

map '/' do
  run MyApp
end
