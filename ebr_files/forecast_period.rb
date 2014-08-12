# app/model/forecast_period.rb

class ForecastPeriod < ActiveRecord::Base
  belongs_to :site
  belongs_to :weather_update
  attr_accessible :dewpoint,
    :forecast_prediction_time,
    :pop,
    :qpf,
    :rh,
    :sky_cover,
    :snow_amount,
    :snow_level,
    :temperature,
    :wind_direction,
    :wind_gust,
    :wind_speed,
    :wx,
    :site_id

  validates :forecast_prediction_time, uniqueness: {scope: :site_id}

  ATTRIBUTES_ARRAY = [
    "temperature",
    "dewPoint",
    "rh",
    "skyCover",
    "windSpeed",
    "windDirection",
    "windGust",
    "pop",
    "qpf",
    "snowAmt",
    "snowLevel",
    "wx"
  ]

  def build_from_xml(period, validDate, site_id)
    @period = period
    @valid_date = validDate
    # Check that pop is being passed and not temp for max pop
    data = {
      forecast_prediction_time: get_full_time,
      temperature: get_temperature,
      dewpoint: get_dew_point,
      rh: get_rh,
      sky_cover: get_sky_cover,
      wind_speed: get_wind_speed,
      wind_direction: get_wind_direction,
      wind_gust: get_wind_gust,
      pop: get_pop,
      qpf: get_qpf,
      snow_amount: get_snow_amt,
      snow_level: get_snow_level,
      wx: wx,
      site_id: site_id
    }
    assign_attributes(data)
  end

  private

  def get_full_time
    validTime = @period.xpath("validTime").text
    DateTime.parse "#{@valid_date} #{validTime}"
  end

  ATTRIBUTES_ARRAY.each do |attribute|
    define_method :"get_#{attribute.underscore}" do
      if attribute == "dewPoint"
        @period.xpath("dewpoint").text
      elsif attribute == "snowAmt"
        @period.xpath("snow_amount").text
      else
        @period.xpath(attribute).text
      end
    end
  end

end
