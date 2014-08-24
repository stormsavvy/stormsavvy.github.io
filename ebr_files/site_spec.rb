require 'spec_helper'
require 'json'
require 'weather/forecast_examiner'
require 'weather/weathergetter'
require 'weather/noaa_forecast'
require 'raven/sidekiq'

describe Site, type: :model do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:site) { FactoryGirl.create(:site, user: user) }
  let!(:ucd) { FactoryGirl.create(:site, user: user) }
  let!(:ucsf) { FactoryGirl.create(:site, user: user) }
  let!(:report) { FactoryGirl.create(:report, site: site) }
  let!(:inspection_event) { FactoryGirl.create(
    :inspection_event,
    site: site
  )}
  let!(:sampling_event) { FactoryGirl.create(
    :sampling_event,
    site: site
  )}

  let(:lat) { site.lat }
  let(:long) { site.long }
  let(:zipcode) { site.zipcode }
  let(:latlong) {[ lat, long ]}
  let(:address) { site.address }
  let(:duration) { 168 }
  let(:interval) { 6 }
  let(:forecast_array) {[
    [90,78,16,8,7,0,14,12,14,14,14,24,50,59,65,49,11,11,5,5,4,4,5,5,6,6,8,8,11],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  ]}
  let(:forecast) {[
    {:date=>"Saturday, 15 February 2014 00:00 UTC", :weather=>6, :rainfall=>0.0},
    {:date=>"Saturday, 15 February 2014 06:00 UTC", :weather=>6, :rainfall=>0.0},
    {:date=>"Saturday, 15 February 2014 12:00 UTC", :weather=>10, :rainfall=>0.0},
    {:date=>"Saturday, 15 February 2014 18:00 UTC", :weather=>10, :rainfall=>0.0},
    {:date=>"Sunday, 16 February 2014 00:00 UTC", :weather=>20, :rainfall=>0.01},
    {:date=>"Sunday, 16 February 2014 06:00 UTC", :weather=>20, :rainfall=>0.01},
    {:date=>"Sunday, 16 February 2014 12:00 UTC", :weather=>22, :rainfall=>0.01},
    {:date=>"Sunday, 16 February 2014 18:00 UTC", :weather=>22, :rainfall=>0.01},
    {:date=>"Monday, 17 February 2014 00:00 UTC", :weather=>61, :rainfall=>0.34},
    {:date=>"Monday, 17 February 2014 06:00 UTC", :weather=>61, :rainfall=>0.34},
    {:date=>"Monday, 17 February 2014 12:00 UTC", :weather=>65, :rainfall=>0.04},
    {:date=>"Monday, 17 February 2014 18:00 UTC", :weather=>65, :rainfall=>0.04},
    {:date=>"Tuesday, 18 February 2014 00:00 UTC", :weather=>20, :rainfall=>0.01},
    {:date=>"Tuesday, 18 February 2014 06:00 UTC", :weather=>20, :rainfall=>0.01},
    {:date=>"Tuesday, 18 February 2014 12:00 UTC", :weather=>10, :rainfall=>0.0},
    {:date=>"Tuesday, 18 February 2014 18:00 UTC", :weather=>10, :rainfall=>0.0},
    {:date=>"Wednesday, 19 February 2014 00:00 UTC", :weather=>5, :rainfall=>0.0},
    {:date=>"Wednesday, 19 February 2014 06:00 UTC", :weather=>5, :rainfall=>0.0},
    {:date=>"Wednesday, 19 February 2014 12:00 UTC", :weather=>5, :rainfall=>0.0},
    {:date=>"Wednesday, 19 February 2014 18:00 UTC", :weather=>5, :rainfall=>0.0},
    {:date=>"Thursday, 20 February 2014 00:00 UTC", :weather=>7, :rainfall=>0.0},
    {:date=>"Thursday, 20 February 2014 06:00 UTC", :weather=>7, :rainfall=>0.0},
    {:date=>"Thursday, 20 February 2014 12:00 UTC", :weather=>7, :rainfall=>0.0},
    {:date=>"Thursday, 20 February 2014 18:00 UTC", :weather=>7, :rainfall=>0.0},
    {:date=>"Friday, 21 February 2014 00:00 UTC", :weather=>15, :rainfall=>0.01},
    {:date=>"Friday, 21 February 2014 06:00 UTC", :weather=>15, :rainfall=>0.01},
    {:date=>"Friday, 21 February 2014 12:00 UTC", :weather=>15, :rainfall=>0.01},
    {:date=>"Friday, 21 February 2014 18:00 UTC", :weather=>15, :rainfall=>0.01}
  ]}
  let(:wg) { WeatherGetter.new }
  let(:nfs) { NoaaForecastService.new(site: site) }
  let(:nf) { NOAAForecast.new(zipcode,duration,interval) }
  let(:json) { JSON.parse(IO.read('./spec/fixtures/wunderground_10day.json')) }
  let(:forecastday) { wg.parse_wunderground_10day(json) }
  let(:response) { IO.read("./spec/lib/weather/noaa_response.xml") }

  before(:all) do
    @data = []
    CSV.foreach(Rails.root.to_s + '/spec/lib/weather/ss_fc_fixture.csv') do |row|
      @data << row
    end
    @data.delete_if { |r| r == [] }
  end

  before(:each) do
    allow(wg).to receive(:wg_table) { return forecastday }
    allow(wg).to receive(:get_forecast).with(zipcode) { json }
    allow(wg).to receive(:forecast_table).with(site) { forecastday }
    allow(wg).to receive(:display_forecast).with(zipcode) { forecastday }

    allow(nf).to receive(:ping_noaa).with([lat, long],duration,interval).and_return(response)
    allow(nfs).to receive(:forecast_table).with(site) { forecast }
    allow(nfs).to receive(:site_forecast).with(site) { forecast }

    allow(site).to receive(:forecast_table) { return forecast }
  end

  describe "validations" do
    it "has a name" do
      site.name = ''
      expect(site).not_to be_valid
    end
  end

  describe 'report associations' do
    it 'responds to reports' do
      expect(site).to respond_to(:reports)
    end

    it 'increases number of reports by 1' do
      expect do
        site.reports.create
      end.to change(Report, :count).by(1)
    end

    it 'destroys associated sites' do
      site.destroy
      expect(Report.find_by_id(report.id)).to be_nil
    end
  end

  describe 'inspection_event associations' do
    it 'responds to inspection_events' do
      expect(site).to respond_to(:inspection_events)
    end

    it 'increases number of inspections by 1' do
      expect do
        site.inspection_events.create
      end.to change(InspectionEvent, :count).by(1)
    end

    it 'destroys associated inspection events' do
      site.destroy
      expect(InspectionEvent.find_by_id(inspection_event.id)).to be_nil
    end
  end

  describe 'sampling_event associations' do
    it 'responds to sampling_events' do
      expect(site).to respond_to(:sampling_events)
    end

    it 'increases number of sampling by 1' do
      expect do
        site.sampling_events.create
      end.to change(SamplingEvent, :count).by(1)
    end

    it 'destroys associated sampling events' do
      site.destroy
      expect(SamplingEvent.find_by_id(sampling_event.id)).to be_nil
    end
  end

  describe 'forecast_period associations' do
    before { site.noaa_table }

    let!(:ecp) { FactoryGirl.create(:site, user: user) }
    let!(:forecast_period) { FactoryGirl.create(
      :forecast_period,
      site: ecp
    )}

    it 'responds to forecast_periods' do
      expect(ecp).to respond_to(:forecast_periods)
    end

    it 'has forecast periods in correct order' do
      expect(site.forecast_periods.count).to eq(29)
    end

    it 'destroys associated sampling events' do
      ecp.destroy
      ecp.forecast_periods.each do |f|
        expect(ForecastPeriod.find_by_id(f.id)).to be_nil
      end
    end

    it 'saves forecast periods' do
      # site.noaa_table
      ecp.forecast_periods.each do |f|
        expect(f.id).to be_between(0,30)
      end
    end
  end

  describe "attributes" do
    it 'has correct attributes' do
      expect(site.description).to eq("North of Lake Merritt")
      expect(site.address_1).to eq('111 Adams Street')
      expect(site.address_2).to eq('Suite 181')
      expect(site.costcode).to eq("450AZC")
      expect(site.size).to eq("20 acres")
      expect(site.exposed_area).to eq("10 acres")
      expect(site.city).to eq('Oakland')
      expect(site.active).to eq(true)
      expect(site.zipcode).to eq(94610)

      expect(site.project_ea).to eq('3A23U4')
      expect(site.wdid_number).to eq('004001005')
      expect(site.construction_phase).to eq('active')

      expect(site.contractor_name).to eq('gcc')
      expect(site.contractor_address_1).to eq('gcc hq')
      expect(site.contractor_address_2).to eq('246 gcc ave')
      expect(site.contractor_city).to eq('santa rosa')
      expect(site.contractor_state).to eq('CA')
      expect(site.contractor_zipcode).to eq('95407')
      expect(site.contract_number).to eq('154009')

      expect(site.wpcm_name).to eq('yoda')
      expect(site.wpcm_company).to eq('gcc')
      expect(site.wpcm_phone).to eq('707-555-9999')
      expect(site.wpcm_emergency_phone).to eq('707-555-9999')
      expect(site.qsp_name).to eq('obi')
      expect(site.qsp_company).to eq('gcc')
      expect(site.qsp_phone).to eq('707-555-9999')
      expect(site.qsp_emergency_phone).to eq('707-555-9999')

      expect(site.total_area).to eq(50.00)
      expect(site.total_dsa).to eq(30.00)
      expect(site.current_dsa).to eq(20.00)
      expect(site.inactive_dsa).to eq(10.00)
      expect(site.time_since_last_storm).to eq('99 days')
      expect(site.precipitation_received).to eq(0.50)

      expect(site.permits).to eq('401/1601')
      expect(site.resident_engineer_name).to eq('yogi')
      expect(site.structures_representative_name).to eq('barney')

      str = "Mon, 27 Jan 2014"
      date = Date.parse str
      expect(site.last_bmp_status).to eq(date)
      expect(site.last_inspection).to eq(date)
      expect(site.last_corrective_action).to eq(date)
      expect(site.last_reap).to eq(date)
      expect(site.last_training).to eq(date)
      expect(site.last_weather_forecast).to eq(date)
      expect(site.last_sampling).to eq(date)

      expect(site).to respond_to(:user)
    end

    it 'checks for active sites' do
      FactoryGirl.create(:site, active: false, user: user)
      expect(user.sites.count).to eq(4)
      expect(user.sites.active.count).to eq(3)
    end
  end

  describe 'lat/long stub values' do 
    it "returns correct stub for oakland latlong" do
      expect(site.lat.round).to eq(38)
      expect(site.long.round).to eq(123)
    end
  end

  describe '#address' do
    it 'returns site address' do
      expect(site.address).to eq(address)
    end
  end

  describe '#precipitation_state' do
    it 'sets rain state to imminent' do
      forecast = [@data[6], @data[7]]
      expect(site.precipitation_state(forecast)).to eq(:imminent)
    end

    it 'sets rain state to warning' do
      forecast = [@data[8], @data[9]]
      expect(site.precipitation_state(forecast)).to eq(:warning)
    end

    it 'sets rain state to watch' do
      forecast = [@data[2], @data[3]]
      expect(site.precipitation_state(forecast)).to eq(:watch)
    end

    it 'sets rain state to clear' do
      forecast = [@data[0], @data[1]]
      expect(site.precipitation_state(forecast)).to eq(:clear)
    end
  end

  describe '#chance_of_rain' do
    let!(:max_rain) {
      site.chance_of_rain
      pop_array = []

      site.forecast_periods.each do |f|
        pop_array << f.pop
      end
      pop = pop_array.max
      site.pop = pop
      site.save
    }
    let!(:pop) { site.pop }

    it "responds to chance_of_rain" do
      expect(site).to respond_to(:chance_of_rain)
    end

    it 'returns chance of rain' do
      expect(pop).to be_between(0,100)
    end

    it "checks pop class" do
      pop.class == Fixnum
    end

    it "converts pop to integer class" do
      expect(pop.to_i.integer?).to eq(true)
    end
  end

  describe '#noaa_table' do
    it "responds to noaa_table" do
      expect(site).to respond_to(:noaa_table)
    end

    it 'returns forecast table' do
      forecast = site.noaa_table
      forecast.each do |f|
        if f[:weather] == -999
          f[:weather] = 0
        end
        expect(f[:weather]).to be_between(0,100)

        if f[:rainfall] == -999
          f[:rainfall] = 0
        end
        expect(f[:rainfall]).to be_between(0,100)
      end
    end
  end

  describe '#save_noaa' do
    it "responds to save_noaa" do
      expect(site).to respond_to(:save_noaa)
    end

    it 'saves noaa api query' do
      site.save_noaa
      expect(site.noaa_forecast.class).to eq(Array)
      expect(site.noaa_forecast.count).to eq(28)
    end

    it 'saves noaa stub value' do
      site.noaa_forecast = forecast
      site.save
      expect(site.noaa_forecast).to eq(forecast)
    end
  end

  describe '#wg_table' do
    it "responds to wg_table" do
      expect(site).to respond_to(:wg_table)
    end

    it 'returns forecast using worker' do
      background_job = WundergroundWorker.perform_async(site.id)
      expect(background_job.class).to eq(String)
    end

    it 'returns forecast using stub value' do
      forecastday = wg.parse_wunderground_10day(json)
      expect(forecastday.count).to eq(10)
      forecastday.each do |f|
        expect(f['pop']).to be_between(0,100)
        expect(f['qpf_allday']['in']).to be_between(0,100)
      end
    end
  end

  describe '#save_wg' do
    before {
      forecast = wg.forecast_table(site)
      site.wg_forecast = forecast
      site.save
    }

    it "responds to save_wg" do
      expect(site).to respond_to(:save_wg)
    end

    it 'checks array class' do
      expect(site.wg_forecast.class).to eq(Array)
    end

    it "checks array elements" do
      forecast = site.wg_forecast
      expect(forecast.count).to eq(10)
      forecast.each do |f|
        expect(f['pop']).to be_between(0,100)
        expect(f['qpf_allday']['in']).to be_between(0,100)
      end
    end

    it 'saves wg stub value' do
      site.wg_forecast = forecastday
      site.save
      expect(site.wg_forecast.class).to eq(Array)
      expect(site.wg_forecast).to eq(forecastday)
    end
  end

  describe '#forecast' do
    it "responds to forecast" do
      expect(site).to respond_to(:forecast)
    end

    it 'returns forecast' do
      forecast = site.forecast
      forecast.each do |sub|
        sub.each do |data|
          if data == -999
            pending 'NOAA API response array index out of bounds'
          else
            expect(data).to be_between(0,100)
          end
        end
      end
    end
  end

  describe '#get_zipcode' do
    it "responds to get_zipcode" do
      expect(site).to respond_to(:get_zipcode)
    end

    it 'returns zipcode' do
      expect(site.get_zipcode).to eq(site.zipcode.to_s)
    end
  end

  describe '#save_geo_coordinates' do
    it "responds to save_geo_coordinates" do
      expect(site).to respond_to(:save_geo_coordinates)
    end

    it 'saves geo coordinates' do
      site.save_geo_coordinates
      expect(site.lat).to be_between(37,39)
      expect(site.long).to be_between(121,123)
    end
  end
end
