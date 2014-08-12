# lib/weather/weathergetter.rb

require 'typhoeus'
require 'json'

include Typhoeus

# APIKEY = Stormsavvy::Application.config.wunderground_apikey
# APIKEY = ENV["APIKEY"] # walter@stormsavvy.com account
APIKEY = ENV["WUNDERGROUND_APIKEY"] # kharma@gmail.com account
NCDC_CDO_KEY = ENV["NCDC_CDO_KEY"]

class WeatherGetter

  attr_reader :forecast, :forecastday

  def initialize
  end

  def make_request(url)
    pp 'sleep for 7s between queries'
    sleep(7) # 10 query/min per terms of use

    request = Typhoeus::Request.new(
      url,
      method: :get,
      timeout: 8000 # milliseconds
      # cache_timeout: 60 # seconds
    )
    @hydra.queue(request)
    @hydra.run
    response = request.response
    data = JSON.parse(response.body)
    return data
  end

  def make_request_with_cache(url, expire_time)
    cache_backup = Rails.cache.read('url')
    api_data = Rails.cache.fetch('url', expires_in: expire_time) do
      pp 'sleep for 7s between queries'
      sleep(7) # 10 query/min terms of use
      new_data = make_request(url)

      if new_data.blank?
        cache_backup
      else
        new_data
      end
    end
    return api_data
  end
=begin
  def log_response(request)
    request.on_complete do |response|
      if response.success?
        @hydra.queue(request)
        @hydra.run
        response = request.response
        data = JSON.parse(response.body)
        return data
      elsif response.timed_out?
        pp 'response timed out'
        log("response timed out")
      elsif response.code == 0
        pp 'an error occurred, check logs'
        log(response.return_message)
      else
        pp 'non-successful http response'
        log("HTTP request failed: " + response.code.to_s)
      end
    end
  end
=end

  def get_forecast(zipcode)
    @hydra = Typhoeus::Hydra.new
    # expire_time = 60.minutes
    # @forecast = make_request_with_cache(url, expire_time) # new cache method

    url = "http://api.wunderground.com/api/#{APIKEY}/forecast10day/q/#{zipcode}.json"
    @forecast = make_request(url)
  end

  def parse_wunderground_10day(forecast)
    # Bad zipcode produces forecast['response']['error']['type'] => "querynotfound"
    # Will need to do some spec for the above.
    @forecastday = forecast['forecast']['simpleforecast']['forecastday']
  end

  def display_forecast(zipcode)
    forecast = get_forecast(zipcode)
    @forecastday = parse_wunderground_10day(forecast)
  end

  def forecast_table(site)
    wg = WeatherGetter.new
    zipcode = site.zipcode
    forecast = wg.get_forecast(zipcode)
    forecastday = wg.parse_wunderground_10day(forecast)
    return forecastday
  end
end
