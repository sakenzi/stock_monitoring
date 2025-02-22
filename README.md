# stock_monitoring

set TZ=Asia/Almaty && bundle exec sidekiq -C sidekiq.yml -r ./app.rb - запуск sidekiq

bundle exec rackup config.ru - запуск sinatra

172.27.203.99

rake db:create - migrate