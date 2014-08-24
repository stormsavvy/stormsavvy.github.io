require 'weather/noaa_forecast'
require 'weather/forecast_examiner'
require 'weather/weathergetter'
require 'displaydate'
require 'json'
require 'redis'
require 'sidekiq'

class Site < ActiveRecord::Base

  include Sidekiq::Worker

  scope :active, -> { where(active: true) }

  belongs_to :user #, counter_cache: true
  belongs_to :inspection_event

  has_many :inspection_events, dependent: :destroy
  accepts_nested_attributes_for :inspection_events

  has_many :sampling_events, dependent: :destroy
  accepts_nested_attributes_for :sampling_events

  has_many :reports, dependent: :destroy
  accepts_nested_attributes_for :reports

  has_many :inspection_event_workflows, dependent: :destroy
  has_many :sampling_event_workflows, dependent: :destroy
  has_many :weather_updates, dependent: :destroy
  has_many :forecast_periods, dependent: :destroy

  after_validation :save_geo_coordinates, if: :zipcode_changed?
  validates :zipcode, :name, :zipcode, presence: true
  serialize :noaa_forecast, Array
  serialize :wg_forecast, JSON

  attr_accessible :name,
    :description,
    :costcode,
    :size,
    :address_1,
    :address_2,
    :state,
    :active,
    :zipcode,
    :city,
    :exposed_area,
    :lat,
    :long,
    :project_ea,
    :risk_level,
    :wdid_number,
    :construction_phase,
    :contractor_name,
    :contractor_address_1,
    :contractor_address_2,
    :contractor_city,
    :contractor_state,
    :contractor_zipcode,
    :contract_number,
    :wpcm_name,
    :wpcm_company,
    :wpcm_phone,
    :wpcm_emergency_phone,
    :qsp_name,
    :qsp_company,
    :qsp_phone,
    :qsp_emergency_phone,
    :total_area,
    :total_dsa,
    :current_dsa,
    :inactive_dsa,
    :time_since_last_storm,
    :precipitation_received,
    :permits,
    :resident_engineer_name,
    :structures_representative_name,
    :last_bmp_status,
    :last_inspection,
    :last_corrective_action,
    :last_reap,
    :last_training,
    :last_weather_forecast,
    :last_sampling,
    :noaa_forecast,
    :wg_forecast,
    :active,
    :pop

  CONSTRUCTION_PHASE = [
    'Highway construction',
    'Plant establishment',
    'Suspension of work'
  ]

  def address
    "#{self.address_1} #{self.address_2} #{self.city} #{self.state} #{self.zipcode}".strip
  end

  attr_reader :rain_state,
    :max_rain,
    :chance_of_rain,
    :forecast,
    :forecast_table

  def chance_of_rain
    nfs = NoaaForecastService.new(site: self)
    nfs.site_forecast(self)
    start_time = DateTime.now.beginning_of_day
    finish_time = DateTime.now.end_of_day
    forecast_period = self.forecast_periods.where(
      'forecast_prediction_time BETWEEN ? AND ?', start_time, finish_time
    )
    forecast_period.order('pop DESC').first
  end

  def noaa_table
    nfs = NoaaForecastService.new(site: self)
    nfs.forecast_table(self)
  end

  def save_noaa
    nfs = NoaaForecastService.new(site: self)
    self.noaa_forecast = nfs.forecast_table(self)
    self.save
  end

  def wg_table
    wg = WeatherGetter.new
    wg.forecast_table(self)
  end

  def save_wg
    wg = WeatherGetter.new
    self.wg_forecast = self.wg_table
    self.save
  end

  def forecast
    nf = NOAAForecast.new(zipcode.to_i)
    forecast = nf.seven_day_weather(zipcode.to_i)
    precipitation_state(forecast)
    @forecast = forecast
  end

  def precipitation_state(forecast)
    if forecast == [[],[]]
      @rain_state = :null
      return
    end
    fe = ForecastExaminer.new(self, forecast)
    fe.find_rain_chance()
    @rain_state = fe.rain
  end

  def check_pop_alert
    forecast = self.forecast
    precipitation_state(forecast)
  end

  def save_geo_coordinates
    unless lat.presence && long.presence
      service = GeocoderService.new(zipcode: zipcode)
      self.update_attributes(service.get_lat_lng)
    end
  end

  def latlng
    [self.lat, self.long]
  end

  def get_zipcode
    return self.zipcode.to_s
  end
end
