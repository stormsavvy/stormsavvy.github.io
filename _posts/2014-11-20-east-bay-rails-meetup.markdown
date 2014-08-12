---
layout: post
title:  "East Bay Rails Meetup"
date:   2014-11-20
categories: rails meetup
---

### Delivering Weather Data in Rails

Presentation Website: [kharma.github.io][kh]

In this meetup presentation, you will learn...

* How to `work with weather data APIs`
* How to `pass data to Action Mailer`
* How to `test each of the above`

### Contributors to this Presentation

Thanks to Dave and Adam for their help:

* David Doolin: [code.daviddoolin.com][dd]
* Adam Barber: [adambarber.tv][ab]

### Introduction

Walter Yu, PE

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
* Example delivers weather data but can be applied to any API data

### Why Weather Data?

Weather affects our small and big ways, from flight delays to natural
disasters...

* Apps for weather-sensitive industries, e.g. outdoor recreation, flight
  forecasting, etc.
* Offers more detailed forecast or containing additional data, e.g. wind
  speed, humidity, etc.
* Offer customers climate history with services such as `[NCDC][ncdc] by
  NOAA`

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

Ruby [Unirest][un] library:

{% highlight ruby %}
API_URL = "http://www.wrh.noaa.gov/forecast/xml/xml.php?"
def contact_noaa
  url = "#{API_URL}duration=#{@duration}&interval=\
    #{@interval}&lat=#{@lat}&lon=#{@lng}"
  @response = Unirest::get(url)
end
{% endhighlight %}

Or [Typhoeus][ty] gem:

{% highlight ruby %}
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

### Parsing Options

[Nokogiri][ng] gem for parsing XML:

{% highlight ruby %}
f = File.open("blossom.xml")
doc = Nokogiri::XML(f)
f.close
{% endhighlight %}

For JSON, parse the returned hash as follows:

{% highlight ruby %}
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


[wg]: http://www.wunderground.com/weather/api/
[ncdc]: http://www.ncdc.noaa.gov/cdo-web/token
[ty]: https://github.com/typhoeus/typhoeus
[noaa]: http://graphical.weather.gov/xml/
[aw]: https://api.accuweather.com/
[ng]: http://nokogiri.org/
[wyu]: http://walteryu.com/
[kh]: http://kharma.github.io/
[dd]: http://code.daviddoolin.com/
[ab]: http://www.adambarber.tv/
[un]: http://unirest.io/
