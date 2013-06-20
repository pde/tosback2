require 'nokogiri'
require 'open-uri'
require 'sanitize'
require 'mechanize' # will probably need to use this instead to handle sites that require session info
# require 'grit'

$rules_path = "../rules/" # Directories should include trailing slash
$results_path = "../crawl/"
$reviewed_crawl_path = "../crawl_reviewed/"
$log_dir = "../logs/"
$error_log = "errors.log"
$run_log = "run.log"
$modified_log = "modified.log"
$empty_log = "empty.log"

class TOSBackApp
  @sites = nil
  # @retry = []
  
  def initialize(path)
    @sites = []
    Dir.foreach(path) do |xml_file| # loop for each xml file/rule
      next if xml_file == "." || xml_file == ".."
       @sites << TOSBackSite.new("#{path}#{xml_file}")
    end
  end #init
  
  def retry_docs
    @sites.each do |site|
      site.docs.each do |doc|
        doc.scrape(false) if doc.has_prev == true
        # puts doc.name if doc.has_prev == true
      end #@docs
    end #@sites
  end #retry_docs
  
  def find_reviewed_doc_changes
    changed = []
    
    @sites.each do |site|
      site.docs.each do |doc|
        if doc.reviewed
          if doc.has_data_changed?
            changed << {site: doc.site, name:doc.name}
          end
        end
      end #@docs
    end #@sites
    
    if changed.length > 0
      io = IO.popen("git add #{$reviewed_crawl_path}")
      io.close
      
      io = IO.popen("git commit -m 'changes for reviewed docs'")
      io.close
      
      require 'mail'
      require './tosback_secrets.rb'
      
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
      
      mail = Mail.deliver do
        to 'jimm@tosdr.org'
        from 'ToSBack <tosback-noreply@tosdr.org>'
        subject 'Changes to a policy that we\'ve reviewed'
        text_part do
          changed.each do |change|
            body = "#{change[:site]}, #{change[:name]} changed in last night's crawl. Have a look at the commit called 'changes for reviewed docs' at https://github.com/tosdr/tosback2/commits/master please!"
          end
        end
      end
      
    end
  end #find_reviewed_changes
  
  def scrape_sites
    @sites.each do |tbs|
      tbs.scrape_docs
    end
  end #scrape_sites
  
  def write_sites
    @sites.each do |tbs|
      tbs.write_docs
    end
  end
  
  def self.find_empty_crawls(path=$results_path, byte_limit)
    Dir.glob("#{path}*") do |filename| # each dir in crawl
      next if filename == "." || filename == ".."

      if File.directory?(filename)
        files = Dir.glob("#{filename}/*.txt")
        if files.length < 1
          TOSBackSite.log_stuff("#{filename} is an empty directory.",$empty_log)
        elsif files.length >= 1
          files.each do |file|
            TOSBackSite.log_stuff("#{file} is below #{byte_limit} bytes.",$empty_log) if (File.size(file) < byte_limit)
          end # files.each
        end # files.length < 1
      end # if File.directory?(filename)
    end # Dir.glob(path)
  end # find_empty_crawls
  
  def self.git_modified
    # git = Grit::Repo.new("../")
    git = IO.popen("git status")

    modified_file = File.open("#{$log_dir}#{$modified_log}", "w")
    modified_file.puts "These files were modified since the last commit:\n\n"
    # git.status.changed.each {|filename| modified_file.puts "#{filename[0]}\n"}
    git.each {|line| modified_file.puts line}
    git.close
    modified_file.close
  end

  attr_accessor :sites
end

class TOSBackSite
  @sitename ||= nil
  @docs ||= nil
  
  def initialize(xml)
    begin
      filecontent = File.open(xml)
      ngxml = Nokogiri::XML(filecontent)
    rescue
      #TODO I don't think this works, but it never happens... :)
      TOSBackSite.log_stuff("Script had trouble opening this file: #{filename}",$error_log)
      # raise ArgumentError, "XML file couldn't be opened"
    ensure
      filecontent.close
    end
    
    @sitename = ngxml.xpath("//sitename[1]/@name").to_s
    @docs = []
    ngxml.xpath("//sitename/docname").each do |doc|
     docs << TOSBackDoc.new({:site => @sitename,:name => doc.at_xpath("./@name").to_s,:url => doc.at_xpath("./url/@name").to_s,:xpath => doc.at_xpath("./url/@xpath").to_s,reviewed: doc.at_xpath("./url/@reviewed").to_s})
    end    
  end #initialize

  def scrape_docs() # get new data from net
    @docs.each do |eachdoc|
      eachdoc.scrape
    end
  end #scrape_docs
  
  def write_docs() # write out to $results_path
    @docs.each do |eachdoc|
      eachdoc.write
    end
  end # write_docs
  
  def puts_docs()
    @docs.each do |eachdoc|
      eachdoc.puts_doc
    end
  end #puts_docs
  
  def self.log_stuff(message,logfile)
    err_log = File.open("#{$log_dir}#{logfile}", "a")
    err_log.puts "#{Time.now} - #{message}\n"
    err_log.close
  end # TOSBackSite.log_stuff
  
  # private :get_crawldata
  attr_accessor :sitename, :docs
end # TOSBackSite

class TOSBackDoc
  @site = nil
  @name ||= nil
  @url ||= nil
  @xpath ||= nil
  @has_prev ||= nil
  @prev_data ||= nil
  @newdata ||= nil
  @reviewed ||= nil
  @save_dir ||= nil
  @save_path ||= nil
  
  def initialize(hash)
    @site = hash[:site]
    @name = hash[:name]
    @url = hash[:url]
    @xpath = (hash[:xpath] == "") ? nil : hash[:xpath]
    @reviewed = (hash[:reviewed] == "") ? nil : hash[:reviewed]
    @save_dir = (@reviewed == nil) ? "#{$results_path}#{@site}/" : "#{$reviewed_crawl_path}#{@site}/"
    @save_path = "#{@save_dir}#{@name}.txt"
  end #init
  
  def scrape(checkprev=true)
    download_full_page()
    if @newdata
      apply_xpath()
      strip_tags()
      format_newdata()
    elsif (!@newdata && (checkprev == true))
      # puts "checkprev == true"
      check_prev()
    end
  end #scrape
  
  def check_prev
    # puts "check_prev - #{$results_path}#{@site}/#{@name}.txt"
    prev = (File.exists?(@save_path)) ? File.open(@save_path) : nil
    unless prev == nil
      if File.size(prev) > 32
        # TOSBackApp.add_to_retry(self)
        @has_prev = true
        # puts "has_prev true"
      end #if
    end #unless
    prev.close if prev
  end #check_prev
  
  def write
    Dir.mkdir(@save_dir) unless File.exists?(@save_dir)
    
    crawl_file = File.open(@save_path,"w") # new file or overwrite old file
    crawl_file.puts @newdata
    crawl_file.close
  end #write
  
  def has_data_changed?
    get_prev_data() if @prev_data == nil
    @prev_data.chomp != @newdata.chomp
  end
  
  def get_prev_data
    prev = (File.exists?(@save_path)) ? File.open(@save_path) : nil
    unless prev == nil
      @prev_data = prev.read
      prev.close
    end
  end
  
  def puts_doc
    puts @newdata
  end #puts_doc
  
  def download_full_page()
    mech = Mechanize.new { |agent| 
      agent.user_agent_alias = 'Mac FireFox'
      agent.post_connect_hooks << lambda { |_,_,response,_|
        if response.content_type.nil? || response.content_type.empty?
          response.content_type = 'text/html'
        end
      }
      agent.ssl_version = 'SSLv3'
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE # less secure. Shouldn't matter for scraping.
      agent.agent.http.reuse_ssl_sessions = false
    }
    # gonext = nil

    begin
      @newdata = mech.get(@url)
    rescue => e
      # puts "error opening page"
      TOSBackSite.log_stuff("#{url}:\t#{e.message}",$error_log)
      # gonext = "skip"
    end
  end #download_full_page
  
  def format_newdata()
    @newdata.gsub!(/\s{2,}/," ") # changes big gaps of space to a single space
    @newdata.gsub!(/\.\s|;\s/,".\n") # adds new line char after all ". "'s
    @newdata.gsub!(/\n\s/,"\n") # removes single spaces at the beginning of lines
    @newdata.gsub!(/>\s*</,">\n<") # newline between tags
  end #format_tos
  
  def apply_xpath()
    if @newdata.class == Mechanize::Page
      @newdata.encoding ||= "UTF-8" # defaults any nil encoding to utf-8
      begin
        if @xpath.nil?
          tos_data = @newdata.search("//body").to_s
        else 
          tos_data = @newdata.search(@xpath).to_s
        end
      rescue  
        @newdata.encoding=("UTF-8")
        if @xpath.nil?
          tos_data = @newdata.search("//body").to_s
        else 
          tos_data = @newdata.search(@xpath).to_s
        end
      end
    elsif @newdata.class == Mechanize::File
      tos_data = @newdata.content
      #TODO log which uris are returning Files and make sure they look okay.
    end

    # log_stuff("scrape page page.class: #{mchdoc.class}","caveman.log")

    @newdata = tos_data
  end #apply_xpath
  
  def strip_tags()
    begin
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => []) # strips non-style html tags and removes content between <script> and <style> tags
      # puts "worked"
    rescue Encoding::CompatibilityError
      # puts "rescued"
      @newdata.encode!("UTF-8", :undef => :replace)
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
    rescue ArgumentError
      # puts "Argument error"
      @newdata.encode!('ISO-8859-1', {:invalid => :replace, :undef => :replace})
      @newdata.encode!('UTF-8', {:invalid => :replace, :undef => :replace})
      @newdata = Sanitize.clean(@newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
    end
  end #strip_tags
  
  attr_accessor :name, :url, :xpath, :newdata, :site, :has_prev, :reviewed
  private :download_full_page, :apply_xpath, :strip_tags, :format_newdata
end #TOSBackDoc

##
# Main starts here :)
##

if ARGV.length == 0
  TOSBackSite.log_stuff("Beginning script!",$run_log)
  
  tba = TOSBackApp.new($rules_path)
  tba.scrape_sites
  tba.retry_docs
  tba.write_sites
  
  tba.find_reviewed_doc_changes

  TOSBackSite.log_stuff("Script finished! Check #{$error_log} for rules to fix :)",$run_log)

  TOSBackApp.git_modified

elsif ARGV[0] == "-empty"
  
  TOSBackApp.find_empty_crawls($results_path,512)

else
  tbs = TOSBackSite.new(ARGV[0])
  tbs.scrape_docs
  
  case ARGV[1]
  when "-w"
    tbs.write_docs
  else
    tbs.puts_docs
  end
end