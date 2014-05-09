require 'singleton'

class TOSBackNotifier
  include Singleton
  
  attr_accessor :changes, :blank, :commit
  
  def initialize
    @changes = []
    @blank = []
    @commit = nil
  end
  
  #TODO DRY this up
  def send_notifications
    # require './tosback_secrets.rb'
    
    secrets = TOSBackSecrets.get_secret_hash
    
    Mail.defaults do
      delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                               :port      => 587,
                               :domain    => "tosdr.org",
                               :user_name => secrets[:u],
                               :password  => secrets[:p],
                               :authentication => 'plain',
                               :enable_starttls_auto => true }
    end
    
    if @changes.length > 0
      bodytext = ""
      @changes.each {|change| bodytext += "#{change[:site]}: #{change[:name]}\n"}
      url = "https://github.com/tosdr/tosback2/commit/" + @commit
      
      mail = Mail.deliver do
        to 'tosdr@googlegroups.com'
        from 'ToSBack <tosback@tosdr.org>'
        subject 'ToSBack: Policy Changes'
        text_part do
          body "#{bodytext} These were changed in last night's crawl. Please have a look at the commit at #{url} to see the differences!"
        end
      end
      
      @changes.each do |change|
        Notification.create(site: change[:site], name: change[:name], diff_url: url)
      end
      
    end
    
    if @blank.length > 0
      bodytext = ""
      @blank.each {|blank| bodytext += "#{blank[:site]}: #{blank[:name]}\n"}
            
      mail = Mail.deliver do
        to 'jimm@tosdr.org'
        from 'ToSBack <tosback@tosdr.org>'
        subject 'Blank scrapes for reviewed policies'
        text_part do
          body "#{bodytext} These were blank in last night's crawl, and have been blank for a couple days. Have a look at the rules!"
        end
      end
      
    end
  end # send_notification_emails
    
  def write_notifications
    if @changes.length > 0
      changes = @changes.join("\n")
      TOSBackApp.log_stuff("Changes that would have been sent:\n#{changes}",$dev_log)
    end
  end #write_notifications
end
