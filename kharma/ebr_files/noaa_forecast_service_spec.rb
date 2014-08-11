require "spec_helper"

describe NoaaForecastService do
  let!(:site) { FactoryGirl.build(:site) }
  let!(:nfs) { NoaaForecastService.new(site: site) }

  context "with a site" do
    describe "with a site with valid lat/lng" do
      it 'creates new nfs object' do
        expect(nfs.class).to eq(NoaaForecastService)
        expect(nfs).not_to eq(nil)
      end

      describe '#get_forecast' do
        it "responds to 'get_forecast'" do
          expect(nfs).to respond_to(:get_forecast)
        end
      end

      describe '#save_results' do
        it "responds to 'save_results'" do
          expect(nfs).to respond_to(:save_results)
        end
      end

      describe '#site_forecast' do
        it 'returns site forecast' do
          expect(nfs).to respond_to(:site_forecast)
          expect(nfs.site_forecast(site).count).to eq(29)
        end
      end

      describe '#forecast_table' do
        it "responds to 'forecast_table'" do
          expect(nfs).to respond_to(:forecast_table)
        end

        it 'returns correct number of elements' do
          forecast_table = nfs.forecast_table(site)
          expect(forecast_table.count).to eq(28)
        end

        context 'when collecting pop and qpf data' do
          it 'returns values between 0 and 100' do
            forecast = nfs.site_forecast(site)
            forecast.each do |f|
              # f[:weather].should be_between(0,100)
              # f[:rainfall].should be_between(0,100)
            end
          end
        end
      end

      describe '#save_forecast_periods' do
        it 'finds forecast' do
          nfs.get_forecast
          pp site.forecast_periods
          # site.forecast_periods.where(pop: forecast.pop)
        end
      end

      context "API query" do
        before :each do
          nfs.get_forecast
        end

        it "sets weather_update after API query" do
          expect(nfs.weather_update.class.name).to eq("WeatherUpdate")
        end

        it "sets forecast_periods after api query" do
          expect(nfs.forecast_periods.count).to eq(29)
        end

        it "saves WeatherUpdate" do
          weather_update_count = WeatherUpdate.count
          nfs.save_results
          expect(WeatherUpdate.count).to eq(weather_update_count + 1)
        end

        it "saves ForecastPeriods" do
          weather_update_count = ForecastPeriod.count
          nfs.save_results
          expect(ForecastPeriod.count).to eq(weather_update_count + 29)
        end
      end
    end
  end

  describe "without a site" do
    it "raises an exception" do
      expect{ expect(NoaaForecastService.new).to }.to raise_error
    end
  end
end
