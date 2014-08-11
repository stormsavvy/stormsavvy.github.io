---
layout: post
title:  "East Bay Rails Meetup"
date:   2014-11-20
categories: rails meetup
---

### Delivering Weather Data in Rails

In this meetup presentation, you will learn...

* How to `work with XML APIs`
* How to `pass data to Action Mailer`
* How to `test each of the above`

### Introduction

* Walter Yu, Website: [walteryu.com][wyu]
* Current building environmental compliance software
* Keep customers out of trouble with regulatory agencies

### Why Weather Data?

* Apps for weather-sensitive industries, e.g. outdoor recreation, flight
  forecasting, etc.
* Offers more detailed forecast or containing additional data, e.g. wind
  speed, humidity, etc.
* Offer customers climate history with services such as [NCDC][ncdc] by
  NOAA

### Why Action Mailer?

* Customers may need daily forecast and/or warnings
* Could be generalized into notification system, where by customers are
  notified based on specific trigger warnings
* Simple example provided for checking forecast daily using rake task,
  but feel free to replace with your own system

### Why TDD?

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

Check out [NOAA][noaa] for more info.

[noaa]: http://weather.gov
[wyu]: http://walteryu.com
