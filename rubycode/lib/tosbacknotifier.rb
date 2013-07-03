require 'singleton'

class TOSBackNotifier
  include Singleton
  
  attr_accessor :changes, :blank
  
  def initialize
    @changes = []
    @blank = []
  end
  
  def send_notifications
    require 'mail'
    require './lib/tosback_secrets.rb'
    
    secrets = TOSBackSecrets.get_secret_hash
    
    if @changes.length > 0
      bodytext = ""
      @changes.each {|change| bodytext += "#{change[:site]}, #{change[:name]}\n"}
      
      Mail.defaults do
        delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                                 :port      => 587,
                                 :domain    => "tosdr.org",
                                 :user_name => secrets[:u],
                                 :password  => secrets[:p],
                                 :authentication => 'plain',
                                 :enable_starttls_auto => true }
      end
      
      mail = Mail.deliver do
        # change to goog group after testing
        to 'jimm@tosdr.org'
        from 'ToSBack <tosback@tosdr.org>'
        subject 'Changes to a policy that we\'ve reviewed'
        text_part do
          body "#{bodytext} These were changed in last night's crawl. Have a look at the commit called 'changes for reviewed docs' at https://github.com/tosdr/tosback2/commits/master please!"
        end
      end
      
    end
    
    if @blank.length > 0
      bodytext = ""
      @blank.each {|blank| bodytext += "#{blank[:site]}, #{blank[:name]}\n"}
            
      Mail.defaults do
        delivery_method :smtp, { :address   => "smtp.sendgrid.net",
                                 :port      => 587,
                                 :domain    => "tosdr.org",
                                 :user_name => secrets[:u],
                                 :password  => secrets[:p],
                                 :authentication => 'plain',
                                 :enable_starttls_auto => true }
      end
      
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
    
end