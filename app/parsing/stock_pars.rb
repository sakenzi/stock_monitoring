require 'selenium-webdriver'
require 'active_record'
require 'pg'

require_relative '../models/stock'
require_relative '../models/stock_data'
require_relative '../config/environment'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')
options.add_argument('--window-size=1920,1080')
options.add_argument('--disable-software-rasterizer')
options.add_argument('--disable-dev-shm-usage')

driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to 'https://www.finam.ru/quotes/stocks/russia/'

wait = Selenium::WebDriver::Wait.new(timeout: 7)

def parse_decimal(value)
  return nil if value.nil? || value.strip.empty?

  value.gsub(/[^\d,.-]/, '').tr(',', '.').to_f
end

def parse_stocks(driver, all_stocks)
    rows = driver.find_elements(xpath: '//*[@id="finfin-local-plugin-quote-table-table-table"]/tbody/tr')
  
    rows.each do |row|
      begin
        stock_element = row.find_element(xpath: "./td[1]/a")
        stock_name = stock_element.text.strip
  
        price = row.find_element(xpath: "./td[2]/span[2]").text.strip rescue nil
        change = row.find_element(xpath: "./td[3]").text.strip rescue nil
        first_price = row.find_element(xpath: "./td[4]").text.strip rescue nil
        max_price = row.find_element(xpath: "./td[5]").text.strip rescue nil
        min_price = row.find_element(xpath: "./td[6]").text.strip rescue nil
        close_price = row.find_element(xpath: "./td[7]").text.strip rescue nil
        quantity = row.find_element(xpath: "./td[8]").text.strip rescue nil

        price = parse_decimal(price)
        change = parse_decimal(change)
        first_price = parse_decimal(first_price)
        max_price = parse_decimal(max_price)
        min_price = parse_decimal(min_price)
        close_price = parse_decimal(close_price)
        quantity = quantity.nil? ? nil : quantity.gsub(/\D/, '').to_i
        
        time_update = Time.now
  
        next if stock_name.empty?
  
        stock = Stock.find_or_create_by(stock_name: stock_name)
  
        StockData.create(
          stock_id: stock.id,
          last_price_deal: price,
          changed_price: change,
          first_price: first_price,
          max_price: max_price,
          min_price: min_price,
          close_price: close_price,
          quantity_selled: quantity,
          time_update: time_update
        )
  
        unless all_stocks.include?(stock_name)
          all_stocks << stock_name
          puts "Добавлена акция: #{stock_name}, цена: #{price}"
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        next
      end
    end
  end

def slow_scroll(driver)
  last_height = driver.execute_script("return document.body.scrollHeight")

  loop do
    begin
      load_more_button = driver.find_element(xpath: '//*[@id="finfin-local-plugin-quote-table-table-more-container"]/button')
      return if load_more_button.displayed?
    rescue Selenium::WebDriver::Error::NoSuchElementError
    end

    10.times do  
        driver.execute_script("window.scrollBy(0, 100);")
        sleep 0.2
      end
  
      new_height = driver.execute_script("return document.body.scrollHeight")
      break if new_height == last_height
    end
  end

def scroll_and_load(driver, wait)
    all_stocks = []
  
    parse_stocks(driver, all_stocks)  
  
    loop do
      slow_scroll(driver)
  
      begin
        load_more_button = wait.until {
          driver.find_element(xpath: '//*[@id="finfin-local-plugin-quote-table-table-more-container"]/button')
        }
        driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", load_more_button)
        sleep 8
        driver.execute_script("arguments[0].click();", load_more_button)
        sleep 2
      rescue Selenium::WebDriver::Error::TimeoutError
        puts "Кнопка 'Показать еще' больше не найдена. Завершаем скроллинг."
        break
      end
    end
  
    parse_stocks(driver, all_stocks)  
    puts "Парсинг завершен!"
  end
  
  at_exit do
    begin
      driver.close
      driver.quit
    rescue Selenium::WebDriver::Error::WebDriverError
      puts "Браузер уже закрыт."
    end

    if Gem.win_platform?
      system("taskkill /IM chrome.exe /F >nul 2>&1")
      system("taskkill /IM chromedriver.exe /F >nul 2>&1")
    end
  end
  
scroll_and_load(driver, wait)
puts "\nПарсинг завершен!"
driver.quit
system("taskkill /IM chrome.exe /F")