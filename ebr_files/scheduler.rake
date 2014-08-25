namespace :scheduler do

  desc "builds reports"
  task build_reports: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      site = user.sites.first
      cem2030 = CEM2030.new(site: site)
      cem2030.build_report
      cem2034 = CEM2034.new(site: site)
      cem2034.build_report
      cem2035 = CEM2035.new(site: site)
      cem2035.build_report
      cem2040 = CEM2040.new(site: site)
      cem2040.build_report
    end
  end

  desc "builds cem2030"
  task build_cem2030: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      site = user.sites.first
      cem = CEM2030.new(site: site)
      cem.build_report
      cem.merge_pdf
    end
  end

  desc "mails cem2030"
  task mail_cem2030: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      user.sites.active.each do |site|
        cem = CEM2030.new(site: site)
        cem.build_report
        cem.merge_pdf

        site.inspection_events.each do |ie|
          date = "#{ie.inspection_date}"
          filename = "#{site.project_ea}_cem2030_full_#{date[0,10]}.pdf"
          path = "#{Rails.root}/public/assets/cem/#{site.project_ea}_cem2030_full_#{date[0,10]}.pdf"
          AlertMailer.cem2030_mailer(user, filename, path)
        end
      end
    end
  end

  desc "builds cem2034"
  task build_cem2034: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      user.sites.each do |site|
        cem = CEM2034.new(site: site)
        cem.build_report
      end
    end
  end

  desc "builds cem2035"
  task build_cem2035: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      user.sites.each do |site|
        cem = CEM2035.new(site: site)
        cem.build_report
      end
    end
  end

  desc "builds cem2040"
  task build_cem2040: :environment do
    # users = User.cem_reports
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]

    users.each do |user|
      # debug rake task for all users...
      # user.sites.active.each do |site|

      user.sites.each do |site|
        cem = CEM2040.new(site: site)
        cem.build_report
      end
    end
  end

  desc "delivers northbay_forecast mailer"
  task northbay_forecast: :environment do
    test_users = [
      'walter@stormsavvy.com',
      'kharma+stormsavvy@gmail.com',
      'wing.wingyu@gmail.com',
      'david.doolin+stormsavvy@gmail.com'
      ]
    test_users.each do |address|
      AlertMailer.northbay_forecast(address)
    end
  end

  desc "delivers pop_alert mailer"
  task pop_alert: :environment do
    # users = User.pop_alert
    user = User.find_by(email: 'walter@stormsavvy.com')

    user.sites.each do |site|
      AlertMailer.pop_alert(user, site)
    end
  end

  desc "checks for pop_alert mailer"
  task check_pop_alert: :environment do
    # Run this task for POP alert mailer
    # users = User.pop_alert
    user = User.find_by(email: 'walter@stormsavvy.com')
    AlertMailer.check_pop_alert(user)
  end

  desc "delivers daily_mailer mailer"
  task daily_mailer: :environment do
    admins = [ (User.find_by email: 'walter@stormsavvy.com') ]
    admins.each do |user|
      AlertMailer.daily_mailer(user)
    end
  end

  desc "delivers daily_forecast mailer"
  task daily_forecast: :environment do
    user = User.find_by(email: 'walter@stormsavvy.com')
    user.sites.active.each do |site|
      AlertMailer.daily_forecast(user, site)
    end
  end

  desc "delivers pester_admins mailer"
  task pester_admins: :environment do
    admins = [
      'walter@stormsavvy.com',
      'kharma+stormsavvy@gmail.com',
      'wing.wingyu@gmail.com',
      'david.doolin+stormsavvy@gmail.com'
    ]
    admins.each do |address|
      UserMailer.pester_admins(address)
    end
  end

  desc "delivers staging_mailer mailer"
  task staging_mailer: :environment do
    if Time.now.sunday?
      admins = [
        'walter@stormsavvy.com',
        'kharma+stormsavvy@gmail.com'
      ]
      admins.each do |address|
        UserMailer.staging_mailer(address)
      end
    end
  end

  desc "delivers mailout mailer"
  task mailout: :environment do
  	users = [
      'walter@stormsavvy.com',
      'kharma+stormsavvy@gmail.com'
    ]
    users.each do |address|
      UserMailer.mailout(address)
    end
  end

  desc "delivers thank you mailer"
  task thankyou: :environment do
    test_users = [
      # 'walter@stormsavvy.com',
      # 'kharma+stormsavvy@gmail.com'
    ]
    test_users.each do |address|
      UserMailer.thankyou(address)
    end
  end

  desc "checks inspection event workflow"
  task iew: :environment do
    iew = InspectionEventWorkflow.new
    iew.inspection_needed?
  end

  desc "saves site pop"
  task site_pop: :environment do
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]
    users.each do |user|
      user.sites.each do |site|
        site.chance_of_rain
        pop_array = []

        site.forecast_periods.each do |f|
          pop_array << f.pop
        end
        pop = pop_array.max
        site.pop = pop
        site.save
      end
    end
  end

  desc "caches noaa_table"
  task noaa_table: :environment do
    if Rails.env == 'production'
      # users = User.all
      users = [ (User.find_by email: 'walter@stormsavvy.com') ]
      users.each do |user|
        user.sites.each do |site|
          Rails.cache.fetch('forecast', expires_in: 60.minutes) do
            site.noaa_table
          end
          Rails.cache.fetch('forecast') { site.noaa_table }
        end
      end
    end
  end

  desc "caches wg_forecast"
  task wg_forecast: :environment do
    # Do not send to all users
    # users = User.all
    users = [ (User.find_by email: 'walter@stormsavvy.com') ]
    users.each do |user|
      user = User.new
      user.sites.each do |site|
        Rails.cache.fetch('forecast', expires_in: 60.minutes) do
          site.wg_table
        end
        Rails.cache.fetch('forecast') { site.wg_table }
      end
  	end
  end
end
