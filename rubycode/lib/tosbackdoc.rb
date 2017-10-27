class TOSBackDoc
  @site = nil
  @name ||= nil
  @url ||= nil
  @xpath ||= nil
  @newdata ||= nil
  @reviewed ||= nil
  @save_dir ||= nil
  @save_path ||= nil
  
  def initialize(hash)
    @site = hash[:site]
    @name = hash[:name]
    @url = hash[:url]
    @xpath = (hash[:xpath] == "") ? nil : hash[:xpath]
    @reviewed = (hash[:reviewed].nil? || hash[:reviewed].empty? || hash[:reviewed] == false || hash[:reviewed] == "false" ) ? nil : hash[:reviewed]
    @save_dir = (@reviewed == nil) ? "#{$results_path}#{@site}/" : "#{$reviewed_crawl_path}#{@site}/"
    @save_path = "#{@save_dir}#{@name}.txt"
  end #init
  
  def scrape
    download_and_filter_with_xpath()
    if @newdata
      #apply_xpath()
      strip_tags()
      format_newdata()
    end
  end #scrape
  
  def write
    unless crawl_empty?
      Dir.mkdir(@save_dir) unless File.exists?(@save_dir)
    
      crawl_file = File.open(@save_path,"w") # new file or overwrite old file
      crawl_file.puts @newdata
      crawl_file.close
    else
      TOSBackApp.log_stuff("#{@site}, #{@name} crawl was empty.",$empty_log)
    end
  end #write
  
  def check_notify
    if @reviewed
      if crawl_empty? && !skip_notify?
        $notifier.blank << {site: @site, name: @name}
      elsif !crawl_empty?
        $notifier.changes << {site: @site, name: @name} if data_changed?
      end
    end
  end
  
  def crawl_empty?
    @newdata.nil? || @newdata.chomp == ""
  end
  
  def data_changed?
    prev_file = File.exists?(@save_path) ? File.open(@save_path) : nil
    if prev_file
      prev_data = prev_file.read
      prev_file.close
    end
    
    if prev_data
      prev_data.chomp != @newdata.chomp
    else
      true
    end
  end
  
  def skip_notify?
    prev_mtime = File.exists?(@save_path) ? File.mtime(@save_path) : nil
    prev_mtime > Time.now - 216000
  end
  
  def puts_doc
    puts @newdata
  end #puts_doc
  
  def download_and_filter_with_xpath
    begin
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, {phantomjs_options: ['--ssl-protocol=any']})
      end

      session = Capybara::Session.new :poltergeist  
      session.driver.browser.js_errors = false
      session.driver.headers = {"User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0"}
      session.visit @url
      raise "404 Error" if session.status_code == 404
      @newdata = @xpath.nil? ? session.find(:xpath, "//body")['innerHTML'] : session.find(:xpath, @xpath)['innerHTML']
    rescue => e
      TOSBackApp.log_stuff("#{url}:\t#{e.message}",$error_log)
    ensure
      session.driver.quit
    end
  end

  def format_newdata()
    @newdata.gsub!(/\s{2,}/," ") # changes big gaps of space to a single space
    @newdata.gsub!(/\.\s|;\s/,".\n") # adds new line char after all ". "'s
    @newdata.gsub!(/\n\s/,"\n") # removes single spaces at the beginning of lines
    @newdata.gsub!(/>\s*</,">\n<") # newline between tags
  end #format_tos
  
  #def apply_xpath()
    #if @newdata.class == Mechanize::Page
      #@newdata.encoding ||= "UTF-8" # defaults any nil encoding to utf-8
      #begin
        #tos_data = @xpath.nil? ? @newdata.search("//body").to_s : @newdata.search(@xpath).to_s
      #rescue  
        #@newdata.encoding=("UTF-8")
        #tos_data = @xpath.nil? ? @newdata.search("//body").to_s : @newdata.search(@xpath).to_s
      #end
    #elsif @newdata.class == Mechanize::File
      #tos_data = @newdata.content
      ##TODO log which uris are returning Files and make sure they look okay.
    #end

    ## log_stuff("scrape page page.class: #{mchdoc.class}","caveman.log")

    #@newdata = tos_data
  #end #apply_xpath
  
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
  private :download_and_filter_with_xpath, :strip_tags, :format_newdata, :skip_notify?, :data_changed?
end #TOSBackDoc
