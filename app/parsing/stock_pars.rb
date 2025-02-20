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

wait = Selenium::WebDriver::Wait.new(timeout: 20)

def parse_decimal(value)
  return nil if value.nil? || value.strip.empty?
  value.gsub(/[^\d,.-]/, '').tr(',', '.').to_f
end

def safe_text(element, xpath)
  element.find_element(xpath: xpath).text.strip rescue nil
end

def hide_interfering_elements(driver)
  interfering_elements = driver.find_elements(css: "a[data-part='link']")
  interfering_elements.each do |el|
    driver.execute_script("arguments[0].style.display='none';", el)
  end
end

def load_all_rows(driver)
  last_row_count = 0
  loop do
    rows = driver.find_elements(xpath: '//*[@id="finfin-local-plugin-quote-table-table-table"]/tbody/tr')
    current_count = rows.size

    begin
      load_more_button = driver.find_element(xpath: '//*[@id="finfin-local-plugin-quote-table-table-more-container"]/button')
      if load_more_button.displayed?
        hide_interfering_elements(driver)
        driver.execute_script("arguments[0].scrollIntoView(true);", load_more_button)
        sleep 1
        driver.execute_script("arguments[0].click();", load_more_button)
        sleep 3
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
    end

    driver.execute_script("window.scrollBy(0, 300);")
    sleep 1

    new_rows = driver.find_elements(xpath: '//*[@id="finfin-local-plugin-quote-table-table-table"]/tbody/tr')
    break if new_rows.size <= current_count && current_count == last_row_count

    last_row_count = current_count
  end
  sleep 5
end

def parse_stocks(driver)
  stocks_data = []
  rows = driver.find_elements(xpath: '//*[@id="finfin-local-plugin-quote-table-table-table"]/tbody/tr')

  rows.each do |row|
    begin
      stock_name = safe_text(row, "./td[1]/a")
      next if stock_name.nil? || stock_name.empty?

      price_text       = safe_text(row, "./td[2]/span[2]")
      change_text      = safe_text(row, "./td[3]")
      first_price_text = safe_text(row, "./td[4]")
      max_price_text   = safe_text(row, "./td[5]")
      min_price_text   = safe_text(row, "./td[6]")
      close_price_text = safe_text(row, "./td[7]")
      quantity_text    = safe_text(row, "./td[8]")

      price       = parse_decimal(price_text)
      change      = parse_decimal(change_text)
      first_price = parse_decimal(first_price_text)
      max_price   = parse_decimal(max_price_text)
      min_price   = parse_decimal(min_price_text)
      close_price = parse_decimal(close_price_text)
      quantity    = quantity_text.nil? ? nil : quantity_text.gsub(/\D/, '').to_i

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
        time_update: Time.now
      )

      stocks_data << {
        stock_name: stock_name,
        price: price,
        change: change,
        first_price: first_price,
        max_price: max_price,
        min_price: min_price,
        close_price: close_price,
        quantity: quantity
      }
    rescue Selenium::WebDriver::Error::NoSuchElementError
      next
    end
  end

  stocks_data
end

load_all_rows(driver)
stocks_data = parse_stocks(driver)
driver.quit

puts "Полученные данные:"
puts stocks_data.inspect
