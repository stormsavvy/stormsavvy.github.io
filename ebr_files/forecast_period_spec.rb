require 'spec_helper'

describe ForecastPeriod, :type => :model do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:site) { FactoryGirl.create(:site, user: user) }
  let!(:site_foo) { FactoryGirl.create(:site, user: user) }
  let!(:wu) { FactoryGirl.create(:weather_update, site: site) }
  let!(:fp) { FactoryGirl.create(
    :forecast_period,
    site: site,
    weather_update: wu
  )}
  let!(:fp_foo) { FactoryGirl.create(
    :forecast_period,
    site: site_foo,
    weather_update: wu
  )}
  let!(:forecast_periods) { [fp, fp_foo] }

  describe "validations" do
    it 'has unique site_id' do
      expect{
        FactoryGirl.create(:forecast_period, site: site)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "site associations" do
    it "has correct association" do
      expect(site).to respond_to(:forecast_periods)
    end

    it "creates new forecast_period" do
      expect{
        site.forecast_periods.create
      }.to change(ForecastPeriod, :count).by(1)
    end

    it "destroys associated forecast_periods" do
      site.destroy
      site_foo.destroy
      forecast_periods.each do |f|
        expect(ForecastPeriod.find_by_id(f.id)).to be_nil
      end
    end
  end

  describe "weather_update associations" do
    it "has correct association" do
      expect(wu).to respond_to(:forecast_periods)
    end

    it "creates new forecast_period" do
      expect{
        wu.forecast_periods.create
      }.to change(ForecastPeriod, :count).by(1)
    end

    it "destroys associated forecast_periods" do
      wu.destroy
      forecast_periods.each do |f|
        expect(ForecastPeriod.find_by_id(f.id)).to be_nil
      end
    end
  end

  describe "attributes" do
    it "has correct attributes" do
      expect(fp.forecast_prediction_time).to eq("2013-09-02 19:25:22")
      expect(fp.temperature).to eq(1)
      expect(fp.dewpoint).to eq(1)
      expect(fp.rh).to eq(1)
      expect(fp.sky_cover).to eq(1)
      expect(fp.wind_speed).to eq(1)
      expect(fp.wind_direction).to eq(1)
      expect(fp.wind_gust).to eq(1)
      expect(fp.pop).to eq(1)
      expect(fp.qpf).to eq(1.5)
      expect(fp.snow_amount).to eq(1.5)
      expect(fp.snow_level).to eq(1)
      expect(fp.wx).to eq("MyString")
      # fp.site.should == nil
      # fp.weather_update.should == nil
    end
  end

  describe "#build_from_xml" do
    it "assigns attributes" do
    end
  end
end
