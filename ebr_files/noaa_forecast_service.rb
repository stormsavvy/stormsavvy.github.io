# app/services/noaa_forecast_service.rb

class NoaaForecastService

  attr_reader :weather_update, :forecast_periods

  API_URL = "http://www.wrh.noaa.gov/forecast/xml/xml.php?"

  def initialize( opts = {} )
    @site = opts[:site]
    @lat = @site.lat
    @lng = @site.long
    @duration = opts[:duration] || 168
    @interval = opts[:interval] || 6
    @forecast_periods = []
  end

  def get_forecast
    # expire_time = 60.minutes
    # @response ||= fetch_noaa_data_with_cache(expire_time)
    @response ||= fetch_noaa_data
  end

  def save_results
    @weather_update.save
    save_forecast_periods
  end

  def site_forecast(site)
    @noaa = NoaaForecastService.new(site: site)
    @noaa.get_forecast
    @noaa.save_results
  end

  def forecast_table(site)
    site_forecast(site)
    @forecast = []
    for i in (0..27)
      date = { date: ProjectLocalTime::format(Date.today + (6*i).hours) }
      weather = { weather: @noaa.forecast_periods[i].pop }
      rainfall = { rainfall: @noaa.forecast_periods[i].qpf }

      date_weather = date.merge!(weather)
      date_weather_rainfall = date_weather.merge!(rainfall)
      @forecast.push(date_weather_rainfall)
    end
    return @forecast
  end

  private

  def save_forecast_periods
    @forecast_periods.each do |forecast|
      # forecast = @site.forecast_periods.find_or_create_by_pop(pop: forecast.pop)
      forecast = @site.forecast_periods.where(pop: forecast.pop)

      unless forecast
        forecast.update_attributes(forecast)
      end
    end
  end

  def fetch_noaa_data
    contact_noaa
    process_xml_response
    process_weather_update
    process_forecast_periods
  end

  def fetch_noaa_data_with_cache(expire_time)
    cache_backup = Rails.cache.read('url')

    Rails.cache.fetch('url', expires_in: expire_time) do

      new_data = fetch_noaa_data

      if new_data.blank?
        cache_backup
      else
        new_data
      end
    end
  end

  def contact_noaa
    url = "#{API_URL}duration=#{@duration}&interval=#{@interval}&lat=#{@lat}&lon=#{@lng}"
    @response = Unirest::get(url)
  end

  def process_xml_response
    @xml = Nokogiri::XML(@response.body)
  end

  def process_weather_update
    @weather_update = @site.weather_updates.new
    @weather_update.build_from_xml(@xml)
  end

  def process_forecast_periods
    forecast_days = @xml.xpath("//forecastDay")
    forecast_days.each do |forecast_day|
      parse_forecast_day(forecast_day)
    end
  end

  def parse_forecast_day(forecast_day)
    validDate = Date.parse(forecast_day.xpath("validDate").text)
    forecast_day.xpath("period").each do |period|
      @forecast_periods << create_forecast_period_record(period, validDate)
    end
  end

  def create_forecast_period_record(period, validDate)
    forecast_period = @weather_update.forecast_periods.new
    forecast_period.build_from_xml(period, validDate, @site.id)
    forecast_period
  end
end
