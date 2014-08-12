# app/model/weather_update.rb

class WeatherUpdate < ActiveRecord::Base
  belongs_to :site
  has_many :forecast_periods, dependent: :destroy
  attr_accessible :duration,
    :elevation,
    :forecast_creation_time,
    :interval,
    :lat,
    :lng

  validates :forecast_creation_time, uniqueness: {scope: [:lat, :lng]}

  accepts_nested_attributes_for :forecast_periods

  def build_from_xml(xml)
    @xml = xml
    data = {
      forecast_creation_time: get_forecast_creation_time,
      lat: get_latitude,
      lng: get_longitude,
      elevation: get_elevation,
      duration: get_duration,
      interval: get_interval
    }
    assign_attributes(data)
  end

  private

  def get_forecast_creation_time
    @xml.xpath('//forecastCreationTime').text
  end

  def get_latitude
    @xml.xpath('//latitude').text.strip.to_f
  end

  def get_longitude
    @xml.xpath('//longitude').text.strip.to_f
  end

  def get_elevation
    @xml.xpath('//elevation').text.strip.to_i
  end

  def get_duration
    @xml.xpath('//duration').text.to_i
  end

  def get_interval
    @xml.xpath('//interval').text.to_i
  end

end
