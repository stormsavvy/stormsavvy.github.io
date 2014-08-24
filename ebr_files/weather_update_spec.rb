require 'spec_helper'

describe WeatherUpdate, :type => :model do

  let!(:user) { FactoryGirl.create(:user) }
  let!(:site) { FactoryGirl.create(:site, user: user) }
  let!(:weather_update) { FactoryGirl.create(:weather_update, site: site) }
  let!(:forecast_period) { FactoryGirl.create(:forecast_period, weather_update: weather_update) }

  describe 'site associations' do
    it 'responds to weather_updates' do
      expect(site).to respond_to(:weather_updates)
    end

    it 'destroys associated sites' do
      site.destroy
      expect(WeatherUpdate.find_by_id(weather_update.id)).to be_nil
    end
  end

  describe 'forecast_period associations' do
    it 'responds to weather_updates' do
      expect(weather_update).to respond_to(:forecast_periods)
    end

    it 'destroys associated sites' do
      weather_update.destroy
      expect(ForecastPeriod.find_by_id(weather_update.id)).to be_nil
    end
  end

  describe "attributes" do
    it 'has correct attributes' do
      expect(weather_update.forecast_creation_time).to eq("2013-09-02 16:45:33")
      expect(weather_update.lat).to eq(1.5)
      expect(weather_update.lng).to eq(1.5)
      expect(weather_update.elevation).to eq(1)
      expect(weather_update.duration).to eq(1)
      expect(weather_update.interval).to eq(1)
    end
  end

  describe '#build_from_xml' do
    it 'responds to #build_from_xml' do
      expect(weather_update).to respond_to(:build_from_xml)
    end
  end
end
