require 'weather/weathergetter'
require 'displaydate'

class AlertMailer < ActionMailer::Base

  default from: "alerts@stormsavvy.com"

  def set_defaults
    @greeting = "Greetings"
    @salutation = "The Storm Savvy Team"
    @support = "Questions? Please email walter@stormsavvy.com"
    @noaa_info = "Forecast is based on the NOAA API."
    @compare = "Compare results with the website:"
    @noaa_forecast = "http://www.wrh.noaa.gov/forecast/wxtables/index.php?"
  end

  def set_northbay
    @subject = "Storm Savvy Daily Forecast: North Bay"

    @location1 = "San Rafael, CA 94901"
    @nf1 = NOAAForecast.new(94901)
    @nf2 = @nf1.forecast_by_zipcode(94901)

    @location2 = "Novato, CA 94949"
    @nf3 = NOAAForecast.new(94949)
    @nf4 = @nf3.forecast_by_zipcode(94949)

    @location3 = "Petaluma, CA 94954"
    @nf5 = NOAAForecast.new(94954)
    @nf6 = @nf5.forecast_by_zipcode(94954)

    @location4 = "Rohnert Park, CA 94928"
    @nf7 = NOAAForecast.new(94928)
    @nf8 = @nf7.forecast_by_zipcode(94928)
  end

  def northbay_forecast(email)
    set_defaults
    set_northbay

    mail(
      to: email,
      subject: @subject
      ).deliver
  end

  def daily_mailer(user)
    set_defaults
    @user = user
    @dd = DisplayDate.new

    if user.has_site?
      user.sites.active.each do |site|
        @noaa_url = "http://www.wrh.noaa.gov/forecast/wxtables/index.php?lat=#{site.lat}&lon=#{site.long}&clrindex=0&table=custom&duration=7&interval=6"
        @wg_url = "http://www.wunderground.com/cgi-bin/findweather/hdfForecast?query=#{site.zipcode}"
        @site = site
      end

      mail(
        to: "#{user.first_name} #{user.last_name} <#{user.email}>",
        subject: "Storm Savvy Daily Mailer for #{ProjectLocalTime::date_only(Date.today)}"
      ).deliver
    end
  end

  def pop_alert(user, site)
    # @users = User.all
    # if @forecast == :imminent then
    # @users.each do |user|
    # end
    set_defaults
    @user = user
    @site = site

    mail(
      to: "#{user.first_name} #{user.last_name} <#{user.email}>",
      subject: "Storm Savvy POP Alert for #{ProjectLocalTime::date_only(Date.today)} - #{site.name}"
    ).deliver
  end

  def check_pop_alert(user)
    if user.has_site?
      user.sites.each do |site|
        site.check_pop_alert
      end
    end
  end

  def daily_forecast(user, site)
    set_defaults
    @user = user
    @site = site

    mail(to: "#{user.first_name} #{user.last_name} <#{user.email}>",
      subject: "Storm Savvy Daily Forecast for #{ProjectLocalTime::date_only(Date.today)} - #{site.name}"
    ).deliver
  end

  def cem2030_mailer(user, filename, path)
    attachments[filename] = File.read(path)
    mail(to: "#{user.first_name} #{user.last_name} <#{user.email}>",
      subject: "Storm Savvy CEM2030 Mailer"
    ).deliver
  end
end
