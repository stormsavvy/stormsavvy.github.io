# spec/lib/weather/weathergetter.rb

require 'spec_helper'
require 'typhoeus'
require 'json'
require 'weather/weathergetter'

include Typhoeus

describe WeatherGetter do

  let(:site) { FactoryGirl.build(:site) }
  let(:ucb) { FactoryGirl.build(:site, name: 'ucb') }
  let(:ecp) { FactoryGirl.build(:site, name: 'ecp') }
  let(:sites) { [ site, ucb, ecp ] }
  let(:zipcode) { site.zipcode }

  let(:json) { JSON.parse(IO.read('./spec/fixtures/wunderground_10day.json')) }
  let(:wg) { WeatherGetter.new }
  let(:ww) { WeatherWorker.new }
  let(:forecast) { wg.get_forecast(zipcode) }
  let(:forecastday) { wg.parse_wunderground_10day(json) }
  let(:result) { query_results.body["postalCodes"][0] }

  # let(:apikey) { ENV["WUNDERGROUND_APIKEY"] }
  # let(:apikey) { Stormsavvy::Application.config.wunderground_apikey }
  # let(:url) { "http://api.wunderground.com/api/#{apikey}/forecast10day/q/#{zipcode}.json" }

  describe '#make_request' do
    it 'makes request' do
      expect(wg.class).to eq(WeatherGetter)
      expect(wg).to respond_to(:make_request)
    end
  end

  describe '#make_request_with_cache' do
    it 'makes request with cache' do
      expect(wg).to respond_to(:make_request_with_cache)
    end
  end

  describe '#display_forecast' do
    it 'checks API response' do
      forecastday = wg.display_forecast(zipcode)
      forecastday.each do |f|
        expect(f['pop']).to be_between(0,100)
        expect(f['qpf_allday'].count).to eq(2)
        expect(f['date']['day']).to be_between(0,31)
        expect(f['qpf_allday']['in']).to be_between(0,100)
        expect{ expect(f["foobar"]).to }.to raise_error
      end
    end

    it 'responds to display_forecast' do
      expect(wg).to respond_to(:display_forecast)
    end

    it "checks array class" do
      expect(forecastday.class).to eq(Array)
    end

    it "checks stub array values" do
      forecastday.each do |f|
        expect(f['pop']).to be_between(0,100)
        expect(f['qpf_allday'].count).to eq(2)
        expect(f['date']['day']).to be_between(0,31)
        expect(f['qpf_allday']['in']).to be_between(0,100)
      end
    end
  end

  describe '#get_forecast' do
    it 'reads json and does not query' do
      expect(json.size).to eq(2)
    end

    it "responds to get_forecast" do
      expect(wg).to respond_to(:get_forecast)
    end

    it "checks array count" do
      forecast = wg.get_forecast(zipcode)
      expect(forecast).to include('response')
      expect(forecast).to include('forecast')
      expect(forecast.size).to eq(2)
      expect(forecast.count).to eq(2)
    end
  end

  describe '#parse_wunderground_10day' do
    it "responds to parse_wunderground_10day" do
      expect(wg).to respond_to(:parse_wunderground_10day)
    end

    it "extracts wunderground's 10 day txt_forecast" do
      forecastday = wg.parse_wunderground_10day(json)
      expect(forecastday.size).to eq(10)
    end
  end

  describe '#forecast_table' do
    it "responds to forecast_table" do
      expect(wg).to respond_to(:forecast_table)
    end

    it 'returns forecast for given site' do
      forecastday = wg.forecast_table(site)
      forecastday.each do |f|
        expect(f['pop']).to be_between(0,100)
        expect(f['qpf_allday'].count).to eq(2)
        expect(f['date']['day']).to be_between(0,31)

        # f['date']['weekday'].count.should == 1
        expect(f['date']['weekday'].class).to eq(String)

        # f['date']['monthname'].count.should == 1
        expect(f['date']['monthname'].class).to eq(String)

        # f['date']['year'].count.should == 1
        expect(f['date']['year'].class).to eq(Fixnum)

        # f['date']['hour'].should == 19
        expect(f['date']['hour'].class).to eq(Fixnum)

        # f['date']['min'].should == 00
        expect(f['date']['min'].class).to eq(String)

        expect(f['date']['tz_short']).to eq('PDT')

        # qpf_allday returns nil when pop = 0
        expect(f['qpf_allday']['in']).to be_between(0,100)
      end
    end
  end
end
