# frozen_string_literal: true

require 'date'

module RpRunner
  class Driver
    def initialize(browser, url:, race_password:, race_group_id:, group_password:)
      @browser = browser
      @url = url
      @race_password = race_password
      @race_group_id = race_group_id
      @group_password = group_password
    end

    def call(data = {})
      Capybara.reset_sessions!

      browser.visit url

      other_adult_btn = browser.find '.differentAdult', visible: false
      other_adult_btn.ancestor('label').click
      
      birth_date = data.fetch(:birth_date)

      month, day, year = birth_date.split('/')

      year = if (0..29).include?(year.to_i)
               "20#{year}"
             else
               "19#{year}"
             end

      orig_birth_date = Date.parse([year, month, day].join('-'))
      birth_date = orig_birth_date.strftime("%m/%d/%Y")

      if (2021-year.to_i) < 18
        throw :alert, 'cannot register kids'
      else
        other_adult_btn = browser.find '.differentAdult', visible: false
        other_adult_btn.ancestor('label').click
      end

      browser.fill_in 'registrant[1][first_name]', with: data[:first_name]
      browser.fill_in 'registrant[1][last_name]', with: data[:last_name]
      browser.fill_in 'registrant[1][email]', with: data[:email]
      browser.fill_in 'registrant[1][confirmEmail]', with: data[:email]
      browser.fill_in 'registrant[1][password]', with: race_password
      browser.fill_in 'registrant[1][confirmPassword]', with: race_password
      browser.fill_in 'registrant[1][dob]', with: birth_date

      browser.find('.label-text', text: data[:gender]).click

      browser.fill_in 'registrant[1][phone]', with: data[:home_phone]
      browser.fill_in 'registrant[1][address1]', with: data[:home_address_1]
      browser.fill_in 'registrant[1][zipcode]', with: data[:home_zip]

      race_name = data.fetch(:ticket_type)
      race_id = RACE_MAPPINGS.fetch(race_name) { puts "unrecognized race name '#{race_name}'"; alert }

      if race_name =~ /virtual/i
        browser.find('span', class: 'label-text', exact_text: 'Virtual Charity Registration').click
      else
        browser.find('span', class: 'label-text', exact_text: 'Charity Registration').click
      end

      browser.find(:xpath, "//option[@value=#{race_id}]").click

      browser.execute_script("window.scrollTo(0, document.body.scrollHeight);")
      browser.find('.ageConfirm').click

      pause

      button = browser.find_button('Continue')
      button.click

      begin
        if browser.find('#errorBox', wait: 2)
          alert
        end
      rescue Capybara::ElementNotFound
      end

      browser.find('span', text: 'Join an Existing Group').click

      browser.find(:xpath, "//option[@value=#{RACE_GROUP_ID}]").click
      browser.find('input[type="password"]').fill_in(with: RACE_GROUP_PASSWORD)

      button = browser.find_button('Continue')

      pause

      button.click

      browser.find('span', text: 'Roland Park Public Annual Fund').click
      browser.find('span', text: 'No').click
      browser.find('span', text: 'Yes, I confirm').click

      browser.fill_in 'question[90999][0][value]', with: data[:emergency_contact_name]
      browser.fill_in 'question[91000][0][value]', with: data[:emergency_contact_phone_number]

      pause

      button = browser.find_button('Continue')
      button.click


      shirt_size = data.fetch(:running_festival_shirt_size)
      browser.find('option', text: shirt_size).click

      pause

      button = browser.find_button('Continue')
      button.click

      # Review registration
      pause

      button = browser.find_button('Complete Registration')
      button.click
    rescue StandardError => e
      puts e.class
      puts e.message

      puts
      puts e.backtrace

      alert

      pry # so we can attempt to manually correct and re-try
    end

    private

    attr_reader :browser, :url, :race_password, :race_group_id, :group_password

    def pause
      if ENV.has_key?('RP_PAUSE')
        %x{say 'pause'}
        pry
      else
        sleep(rand(0..3.0))
      end
    end

    def alert
      %x{say 'alert'}
      pry
    end

    RACE_MAPPINGS = {
      '10k Race' => '446245',
      '5k Race' => '446244',
      'BaltiMORON-a-thon' => '446246',
      'Half Marathon' => '446243',
      'Marathon' => '446242',

      'Virtual 5k' => '482873',
      'Virtual 10k' => '482872'
    }

    private_constant :RACE_MAPPINGS
  end
end
