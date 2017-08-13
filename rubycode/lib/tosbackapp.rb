class TOSBackApp
  @docs ||= nil
  
  def initialize(path)
    @docs = []
    
    Dir.foreach(path) do |xml_file| # loop for each xml file/rule
      next if xml_file == "." || xml_file == ".."
      
      filecontent = File.open(path + xml_file)
      ngxml = Nokogiri::XML(filecontent)
      filecontent.close
    
      site = ngxml.xpath("//sitename[1]/@name").to_s
      ngxml.xpath("//sitename/docname").each do |doc|
        @docs << TOSBackDoc.new({site: site, name: doc.at_xpath("./@name").to_s, url: doc.at_xpath("./url/@name").to_s, xpath: doc.at_xpath("./url/@xpath").to_s, reviewed: doc.at_xpath("./url/@reviewed").to_s})
      end
    end
  end #init
  
  def run_app
    scrape_docs
    check_notify_for_docs
    write_docs
    TOSBackApp.log_stuff("Script finished! Check #{$error_log} for rules to fix :)",$run_log)    
    TOSBackApp.git_modified
    git_commit
    $notifier.send_notifications
  end

  def run_app_dev
    scrape_docs
    check_notify_for_docs
    write_docs
    $notifier.write_notifications
  end
  
  def git_commit
    io = IO.popen("git add #{$reviewed_crawl_path}")
    io.close
        
    io = IO.popen("git commit -m 'changes for reviewed docs'")
    io.close
    
    if $notifier.changes.length > 0
      io = IO.popen("git rev-parse --verify HEAD")
      $notifier.commit = io.read.strip
      io.close
    end
    
    io = IO.popen("git add #{$results_path} #{$log_dir}")
    io.close
        
    io = IO.popen("git commit -m 'crawls'")
    io.close
  end
  
  def check_notify_for_docs
    @docs.each do |doc|
      doc.check_notify
    end
  end
  
  def scrape_docs
    #docs_length = @docs.length
    @docs.each_with_index do |doc, i|
      #puts "scraping #{i + 1} of #{docs_length}"
      doc.scrape
    end
  end #scrape_docs
  
  def write_docs
    @docs.each do |doc|
      doc.write
    end
  end
  
  def self.find_empty_crawls(path=$results_path, byte_limit)
    Dir.glob("#{path}*") do |filename| # each dir in crawl
      next if filename == "." || filename == ".."

      if File.directory?(filename)
        files = Dir.glob("#{filename}/*.txt")
        if files.length < 1
          TOSBackApp.log_stuff("#{filename} is an empty directory.",$empty_log)
        elsif files.length >= 1
          files.each do |file|
            TOSBackApp.log_stuff("#{file} is below #{byte_limit} bytes.",$empty_log) if (File.size(file) < byte_limit)
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
  
  def self.log_stuff(message,logfile)
    err_log = File.open("#{$log_dir}#{logfile}", "a")
    err_log.puts "#{Time.now} - #{message}\n"
    err_log.close
  end # TOSBackApp.log_stuff

  # attr_accessor :docs
end
