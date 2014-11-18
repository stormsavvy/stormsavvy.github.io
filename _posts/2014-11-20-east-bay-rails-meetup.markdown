---
layout: post
title:  "East Bay Rails Meetup"
date:   2014-11-20
categories: meetup
---

### Delivering Weather Data in Rails

Examples and slides:

* Code examples located on [github][code]
* Presentation Website: [stormsavvy.github.io][kh]

In this meetup presentation, you will learn:

* How to work with weather data APIs
* How to pass data to Action Mailer
* How to test each of the above

### Contributors

Thanks to Dave and Adam for their help:

* David Doolin: [code.daviddoolin.com][dd]
* Adam Barber: [adambarber.tv][ab]

### Introduction

Walter Yu, P.E.

* Background in civil and transportation engineering
* Current building environmental compliance software
* Keep customers out of trouble with regulatory agencies
* Help customers handle compliance more efficiently

### Problem Space

How to deliver event-based notifications to your customers:

* Apps are rarely stand-alone and require logic that communicates with
  the outside world
* How to deliver relevant to data to your customers?
* How to develop in a modular fashion that allows components to be
  reused?

### Solution

Utilize the Rails framework and Ruby gems for checking and delivering
data:

* ActionMailer allows email templates to be easily passed as views
* Rake tasks can be set to make HTTP requests
* Testing tools ensure that requests are made and mail is delivered

### Why Weather Data?

Weather affects our small and big ways, from flight delays to natural
disasters...

* Apps for weather-sensitive industries, e.g. outdoor recreation, flight
  forecasting, etc.
* Offers more detailed forecast or containing additional data, e.g. wind
  speed, humidity, etc.
* Offer customers climate history with services such as [NCDC][ncdc] by
  NOAA
* Example delivers weather data but can be applied to any API data

### Why Action Mailer?

Because some customers may prefer plain-vanilla email...

* Customers may need daily forecast and/or warnings
* Could be generalized into notification system, where by customers are
  notified by specific events
* Example provided for checking forecast using rake task

### Why TDD?

Because your models, services, mailers and tasks will be working
together...

* Tests verify API response and passing data thru notification system
* Reduce errors when multiple classes are interacting to deliver data
* Ensure code quality when more features are build on top of existing
  ones

### Data Options

Weather data is consumed either as JSON or (older) XML APIs:

* [NOAA][noaa] XML API
* [Wunderground][wg] JSON API
* [AccuWeather][aw] JSON API
* [NCDC][ncdc] JSON API

### Making HTTP Requests:

For XML, use the Ruby [Unirest][un] library:

{% highlight ruby %}
# app/services/noaa_forecast_service.rb
API_URL = "http://www.wrh.noaa.gov/forecast/xml/xml.php?"
def contact_noaa
  url = "#{API_URL}duration=#{@duration}&interval=\
    #{@interval}&lat=#{@lat}&lon=#{@lng}"
  @response = Unirest::get(url)
end
{% endhighlight %}

Or JSON, use the [Typhoeus][ty] gem:

{% highlight ruby %}
# Example from github page at http://typhoeus.github.io
request = Typhoeus::Request.new(
  url,
  method: :get,
  timeout: 8000
)
@hydra.queue(request)
@hydra.run
response = request.response
data = JSON.parse(response.body)
return data
{% endhighlight %}

### Parsing the Response

[Nokogiri][ng] gem for parsing XML:

{% highlight ruby %}
f = File.open("blossom.xml")
doc = Nokogiri::XML(f)
f.close
{% endhighlight %}

For JSON, parse the returned hash as follows:

{% highlight ruby %}
# lib/weather/weathergetter.rb
def get_forecast(zipcode)
  @hydra = Typhoeus::Hydra.new
  url = "http://api.wunderground.com/api/#{APIKEY}\
    /forecast10day/q/#{zipcode}.json"
  @forecast = make_request(url)
end

def parse_wunderground_10day(forecast)
  @forecastday = forecast['forecast']['simpleforecast']['forecastday']
end
{% endhighlight %}

### Saving Data Using Model Attributes

Use case:

* NOAA data is specified by regulatory permits
* As a result, NOAA data needed to be saved
* Data can be saved using model attributes

Review NOAA data models:

* [app/model/weather_update.rb][wu]
* [app/model/forecast_period.rb][fp]

{% highlight ruby %}
# app/model/weather_update.rb
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
{% endhighlight %}

{% highlight ruby %}
# app/model/forecast_period.rb
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
{% endhighlight %}

Review model spec:

* [spec/model/weather_update_spec.rb][wu_spec]
* [spec/model/forecast_period_spec.rb][fp_spec]

{% highlight ruby %}
# spec/model/weather_update_spec.rb
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
{% endhighlight %}

{% highlight ruby %}
# spec/model/forecast_period_spec.rb
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
{% endhighlight %}

### NOAA Forecast Service

Organize external services into classes under app/services:

* Forecast service retrieves API response, then stores it in the model
* Assembles forecast table to be passed into the mailer

Review NOAA forecast service:

* [app/services/noaa_forecast_service.rb][nf]
* [spec/services/noaa_forecast_service_spec.rb][nf_spec]

{% highlight ruby %}
# app/services/noaa_forecast_service.rb
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
    date = { date: ProjectLocalTime::format(Date.today + (6*i).hours)}
    weather = { weather: @noaa.forecast_periods[i].pop }
    rainfall = { rainfall: @noaa.forecast_periods[i].qpf }

    date_weather = date.merge!(weather)
    date_weather_rainfall = date_weather.merge!(rainfall)
    @forecast.push(date_weather_rainfall)
  end
  return @forecast
end
{% endhighlight %}

{% highlight ruby %}
# spec/services/noaa_forecast_service_spec.rb
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
{% endhighlight %}

### Weather Data & Site Model

* Organize weather data to be site specific in each model
* Display data in forecast table, which will be shown by the mailer

Review site model:

* [app/models/site.rb][site]
* [spec/models/site_spec.rb][site_spec]

{% highlight ruby %}
# app/models/site.rb
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
{% endhighlight %}

{% highlight ruby %}
# spec/models/site_spec.rb
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
{% endhighlight %}

### Action Mailer Basics

* Created using `rails generate mailer`
* See Rails [guides][am] for quick start on mailers
* Mailers include inline images, attachments and spec

### Organizing the Mailer

* Organize mailers by type such as alerts, user, etc.
* Mailers will contain methods for each mailer
* Methods will then pass data into the view

Review mailer, view and spec:

* [app/mailers/alert_mailer.rb][alert]
* [app/views/alert_mailer/_forecast_table.html.haml][alert_view]
* [spec/mailers/alert_mailer_spec.rb][alert_spec]

{% highlight ruby %}
# app/mailers/alert_mailer.rb
def daily_mailer(user)
  set_defaults
  @user = user
  @dd = DisplayDate.new

  if user.has_site?
    user.sites.active.each do |site|
      @noaa_url = "http://www.wrh.noaa.gov/forecast/wxtables/index.php?\
        lat=#{site.lat}&lon=#{site.long}&clrindex=0&table=custom&duration=7&interval=6"
      @wg_url = "http://www.wunderground.com/cgi-bin/findweather/hdfForecast?\
        query=#{site.zipcode}"
      @site = site
    end

    mail(
      to: "#{user.first_name} #{user.last_name} <#{user.email}>",
      subject: "Storm Savvy Daily Mailer for #{ProjectLocalTime::date_only(Date.today)}"
    ).deliver
  end
end
{% endhighlight %}

{% highlight ruby %}
# spec/mailers/alert_mailer_spec.rb
describe "daily_mailer" do
  let!(:mailer) { AlertMailer.daily_mailer(user).deliver }

  it "renders headers" do
    expect(mailer.subject).to eq("Storm Savvy Daily Mailer for\
     #{ProjectLocalTime::date_only(Date.today)}")
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
end
{% endhighlight %}

### Sending Mail with Rake Tasks

* Deliver mailers using rake tasks
* Tasks should only handle recipients and basics
* Leave remaining logic in mailer (model) logic
* Spec out mailer logic within its own spec

Review rake tasks:

* [lib/tasks/scheduler.rake][rake]

### Mailer Demo:

* Demo with daily forecast delivered by user and site
* Additional logic can be added to watch forecast
* Options for adding attachments, users, etc.

### Conclusion

* XML is out, JSON is in when working with external services
* Additional work when it comes to XML data
* Model logic wraps around response data
* Format data for display within the view
* Contain logic within model and mailer, pass onto rake task
* Spec out each section to ensure code quality

### Questions?

Contact:

* Email: stormsavvy@gmail.com
* Twitter: @walteryu

[code]: https://github.com/stormsavvy/stormsavvy.github.io/tree/master/ebr_files
[kh]: http://stormsavvy.github.io/
[wg]: http://www.wunderground.com/weather/api/
[ncdc]: http://www.ncdc.noaa.gov/cdo-web/token
[ty]: https://github.com/typhoeus/typhoeus
[noaa]: http://graphical.weather.gov/xml/
[aw]: https://api.accuweather.com/
[ng]: http://nokogiri.org/
[wyu]: http://walteryu.com/
[dd]: http://code.daviddoolin.com/
[ab]: http://www.adambarber.tv/
[un]: http://unirest.io/
[wu]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/weather_update.rb
[fp]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/forecast_period.rb
[wu_spec]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/weather_update_spec.rb
[fp_spec]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/forecast_period_spec.rb
[nf]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/noaa_forecast_service.rb
[nf_spec]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/noaa_forecast_service_spec.rb
[site]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/site.rb
[site_spec]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/site_spec.rb
[am]: http://edgeguides.rubyonrails.org/action_mailer_basics.html
[alert]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/alert_mailer.rb
[alert_view]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/_forecast_table.html.haml
[alert_spec]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/alert_mailer_spec.rb
[rake]: https://github.com/stormsavvy/stormsavvy.github.io/blob/master/ebr_files/scheduler.rake
