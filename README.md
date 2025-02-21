# stock_monitoring

bundle exec sidekiq -C sidekiq.yml -r ./app.rb - запуск sidekiq
bundle exec rackup config.ru - запуск sinatra

172.27.203.99