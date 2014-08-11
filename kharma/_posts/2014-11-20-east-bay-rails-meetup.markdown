---
layout: post
title:  "East Bay Rails Meetup"
date:   2014-11-20
categories: rails meetup
---

### Delivering Weather Data in Rails

Presentation Website: [kharma.github.io][kh]

In this meetup presentation, you will learn...

* How to `work with XML APIs`
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
* Simple example provided for checking forecast using rake task

### Why TDD?

Because your models, services, mailers and tasks will be working
together...

* Tests verify API response and passing data thru notification system
* Reduce errors when multiple classes are interacting to deliver data
* Ensure code quality when more features are build on top of existing
  ones

### Data Options

* [NOAA][noaa] XML API
* [Wunderground][wg] JSON API
* [AccuWeather][aw] JSON API
* [NCDC][ncdc] JSON API

### Parsing Options

XML

* Ruby Unirest for handling response or...
* [Typhoeus][ty] gem
* [Nokogiri][ng] gem for parsing

Highlight like `this!`

Code snippets like this:

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}


[wg]: http://www.wunderground.com/weather/api/
[ncdc]: http://www.ncdc.noaa.gov/cdo-web/token
[ty]: https://github.com/typhoeus/typhoeus
[noaa]: http://graphical.weather.gov/xml/
[aw]: https://api.accuweather.com/
[ng]: http://nokogiri.org/
[wyu]: http://walteryu.com
