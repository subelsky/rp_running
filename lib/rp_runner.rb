# frozen_string_literal: true

require 'capybara'

Capybara.app_host = 'https://runsignup.com/'
Capybara.current_driver = :selenium
Capybara.run_server = false

Capybara.register_driver :selenium do |app|  
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|  
  config.default_max_wait_time = 1 # seconds
  config.default_driver = :selenium
end
