require 'spec_helper'
require 'date'

include Warden::Test::Helpers
Warden.test_mode!

describe AlertMailer, :type => :mailer do

  before {
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  }

  after {
    ActionMailer::Base.deliveries.clear
  }

  let!(:user) { FactoryGirl.build(
    :user,
    first_name: 'yoda',
    last_name: 'jedi',
    email: 'yoda@starwars.com'
  )}
  let!(:site) { FactoryGirl.create(
    :site,
    user: user
  )}

  describe "#northbay_forecast" do
    let!(:mailer) { AlertMailer.northbay_forecast(user.email).deliver }

    it "sets correct settings" do
      expect(mailer.subject).to eq("Storm Savvy Daily Forecast: North Bay")
      expect(mailer.to).to eq(["#{user.email}"])
      expect(mailer.from).to eq(["alerts@stormsavvy.com"])
    end

    it "renders body" do
      expect(mailer.body.encoded).to match("Greetings")
      expect(mailer.body.encoded).to match("Listed below are the daily weather forecasts")
      expect(mailer.body.encoded).to match("Please email walter@stormsavvy.com")
      expect(mailer.body.encoded).to match("The Storm Savvy Team")
    end

    it "delivers mailer" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it 'delays delivery using sidekiq' do
      expect { AlertMailer.delay.northbay_forecast(user.email)}.to change(
        Sidekiq::Extensions::DelayedMailer.jobs, :size
      ).by(1)
    end
  end

  describe "daily_mailer" do
    let!(:mailer) { AlertMailer.daily_mailer(user).deliver }

    it "renders headers" do
      expect(mailer.subject).to eq("Storm Savvy Daily Mailer for #{ProjectLocalTime::date_only(Date.today)}")
      expect(mailer.to).to eq(["#{user.email}"])
      expect(mailer.from).to eq(["alerts@stormsavvy.com"])
    end

    it "renders body" do
      expect(mailer.body.encoded).to match("Greetings")
      expect(mailer.body.encoded).to match("Please email walter@stormsavvy.com")
      expect(mailer.body.encoded).to match("The Storm Savvy Team")
    end

    it 'creates noaa forecast table' do
      nfs = NoaaForecastService.new(site: site)
      forecast = nfs.forecast_table(site)
      expect(nfs).to respond_to(:forecast_table)
      forecast.each do |f|
        expect(f[:weather]).to be_between(0,100)
        expect(f[:rainfall]).to be_between(0,100)
      end
    end

    it 'creates wunderground forecast' do
      wg = WeatherGetter.new
      forecast = wg.get_forecast(site.zipcode)
      expect(wg).to respond_to(:get_forecast)

      forecastday = wg.parse_wunderground_10day(forecast)
      expect(forecastday.count).to eq(10)

      forecastday.each do |f|
        expect(f['pop']).to be_between(0,100)
      end
    end

    it "delivers mail" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders successfully" do
      expect { mailer }.not_to raise_error
    end

    it 'delays delivery using sidekiq' do
      expect { AlertMailer.delay.daily_mailer(user.email)}.to change(
        Sidekiq::Extensions::DelayedMailer.jobs, :size
      ).by(1)
    end
  end

  describe "pop_alert" do
    let!(:mailer) { AlertMailer.pop_alert(user, site).deliver }

    it "renders headers" do
      expect(mailer.subject).to match(/Storm Savvy POP Alert for #{ProjectLocalTime::date_only(Date.today)} - #{site.name}/)
      expect(mailer.to).to eq(["#{user.email}"])
      expect(mailer.from).to eq(["alerts@stormsavvy.com"])
    end

    it "delivers mailer" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders successfully" do
      expect { mailer }.not_to raise_error
    end

    it 'delays delivery using sidekiq' do
      expect { AlertMailer.delay.pop_alert(user.email)}.to change(
        Sidekiq::Extensions::DelayedMailer.jobs, :size
      ).by(1)
    end
  end

  describe "daily_forecast" do
    let!(:mailer) { AlertMailer.daily_forecast(user, site).deliver }

    it "renders headers" do
      expect(mailer.subject).to match(/Storm Savvy Daily Forecast for #{ProjectLocalTime::date_only(Date.today)} - #{site.name}/)
      expect(mailer.to).to eq(["#{user.email}"])
      expect(mailer.from).to eq(["alerts@stormsavvy.com"])
    end

    it "delivers mailer" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders successfully" do
      expect { mailer }.not_to raise_error
    end

    it 'delays delivery using sidekiq' do
      expect { AlertMailer.delay.daily_forecast(user.email)}.to change(
        Sidekiq::Extensions::DelayedMailer.jobs, :size
      ).by(1)
    end
  end

  describe "cem2030_mailer" do
    let!(:filename) { "filename.pdf" }
    let!(:ie) { FactoryGirl.create(:inspection_event, site: site) }
    let!(:date) { "#{ie.inspection_date}" }
    let!(:path) { "#{Rails.root}/public/assets/cem/#{site.project_ea}_cem2030_full_#{date[0,10]}.pdf" }
    let!(:mailer) { AlertMailer.cem2030_mailer(user, filename, path).deliver }

    before {
      cem = CEM2030.new(site: site)
      cem.build_report
      cem.merge_pdf
    }

    it "renders headers" do
      expect(mailer.subject).to have_text("Storm Savvy CEM2030 Mailer")
      expect(mailer.to).to eq(["#{user.email}"])
      expect(mailer.from).to eq(["alerts@stormsavvy.com"])
    end

    it "delivers mailer" do
      expect(ActionMailer::Base.deliveries.count).to eq(2)
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "renders successfully" do
      expect { mailer }.not_to raise_error
    end

    it 'delays delivery using sidekiq' do
      expect { AlertMailer.delay.cem2030_mailer(user, filename, path)}.to change(
        Sidekiq::Extensions::DelayedMailer.jobs, :size
      ).by(1)
    end
  end
end
