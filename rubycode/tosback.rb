require 'nokogiri'
require 'open-uri'
require 'sanitize'
require 'mechanize' # will probably need to use this instead to handle sites that require session info
# require 'grit'

$rules_path = "../rules/"
$results_path = "../crawl/"
$log_dir = "../logs/"
$error_log = "errors.log"
$run_log = "run.log"
$modified_log = "modified.log"
$empty_log = "empty.log"

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
     docs << TOSBackDoc.new({:site => @sitename,:name => doc.at_xpath("./@name").to_s,:url => doc.at_xpath("./url/@name").to_s,:xpath => doc.at_xpath("./url/@xpath").to_s})
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
  @prevdata ||= nil
  @newdata ||= nil
  
  def initialize(hash)
    @site = hash[:site]
    @name = hash[:name]
    @url = hash[:url]
    @xpath = (hash[:xpath] == "") ? nil : hash[:xpath]
  end #init
  
  def scrape
    download_full_page()
    apply_xpath() if @newdata
    strip_tags() if @newdata
    format_newdata() if @newdata
  end #scrape
  
  def write
    new_path = "#{$results_path}#{@site}/"
    Dir.mkdir(new_path) unless File.exists?(new_path)
    
    new_path = "#{new_path}#{@name}.txt"
    crawl_file = File.open(new_path,"w") # new file or overwrite old file
    crawl_file.puts @newdata
    crawl_file.close
  end #write
  
  def puts_doc
    puts @newdata
  end #puts_doc
  
  def download_full_page()
    mech = Mechanize.new { |agent| 
      agent.user_agent_alias = 'Mac FireFox'
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
  
  attr_accessor :name, :url, :xpath, :newdata
  private :download_full_page, :apply_xpath, :strip_tags, :format_newdata
end #TOSBackDoc

def git_modified
  # git = Grit::Repo.new("../")
  git = IO.popen("git status")

  modified_file = File.open("#{$log_dir}#{$modified_log}", "w")
  modified_file.puts "These files were modified since the last commit:\n\n"
  # git.status.changed.each {|filename| modified_file.puts "#{filename[0]}\n"}
  git.each {|line| modified_file.puts line}
  git.close
  modified_file.close
end

def find_empty_crawls(path, byte_limit)
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

##
# code stuff starts here :)
##

if ARGV.length == 0
  TOSBackSite.log_stuff("Beginning script!",$run_log)
  
  Dir.foreach($rules_path) do |xml_file| # loop for each xml file/rule
    next if xml_file == "." || xml_file == ".."
     tb = TOSBackSite.new("#{$rules_path}#{xml_file}")
     tb.scrape_docs
     tb.write_docs
  end

  TOSBackSite.log_stuff("Script finished! Check #{$error_log} for rules to fix :)",$run_log)

  git_modified

elsif ARGV[0] == "-empty"
  
  find_empty_crawls($results_path,512)

else
  tb = TOSBackSite.new(ARGV[0])
  tb.scrape_docs
  
  case ARGV[1]
  when "-w"
    tb.write_docs
  else
    tb.puts_docs
  end
end