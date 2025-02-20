require 'selenium-webdriver'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')
options.add_argument('--window-size=1920,1080')
options.add_argument('--disable-software-rasterizer')
options.add_argument('--disable-dev-shm-usage')

driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to 'https://www.finam.ru/quotes/stocks/russia/'

wait = Selenium::WebDriver::Wait.new(timeout: 12)

def parse_stocks(driver, all_stocks)
    rows = driver.find_elements(xpath: '//*[@id="finfin-local-plugin-quote-table-table-table"]/tbody/tr')

    rows.each_with_index do |row, index|
        begin
            stock_element = row.find_element(xpath: "./td[1]/a") 
            stock_name = stock_element.text.strip

            unless stock_name.empty? || all_stocks.include?(stock_name)
                all_stocks << stock_name
                puts stock_name
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

        driver.execute_script("window.scrollBy(0, 300);")
        sleep 0.5

        new_height = driver.execute_script("return document.body.scrollHeight")
        break if new_height == last_height
    end
end

def scroll_and_load(driver, wait)
    all_stocks = []

    loop do
        parse_stocks(driver, all_stocks) 

        slow_scroll(driver)

        begin
            load_more_button = wait.until {
                driver.find_element(xpath: '//*[@id="finfin-local-plugin-quote-table-table-more-container"]/button')
            }

            driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", load_more_button)
            sleep 1

            driver.execute_script("arguments[0].click();", load_more_button)
            sleep 3
        rescue Selenium::WebDriver::Error::ElementClickInterceptedError
            puts "Клик перехвачен! Пробуем другой способ..."
            driver.execute_script("arguments[0].click();", load_more_button)
            sleep 3
        rescue Selenium::WebDriver::Error::TimeoutError
            puts "Кнопка 'Показать еще' больше не найдена. Завершаем парсинг."
            break
        end
    end

    all_stocks
end

all_stocks = scroll_and_load(driver, wait)

puts "\nВсего найдено #{all_stocks.size} акций:"
all_stocks.each { |stock| puts stock }

driver.quit
