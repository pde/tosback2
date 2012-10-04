require 'nokogiri'
require 'open-uri'
require 'sanitize'
# require 'grit'

rules_path = "../rules_test/"
results_path = "../crawl/"
$log_dir = "../logs/"
$error_log = "errors.log"
$run_log = "run.log"
$modified_log = "modified.log"

def log_stuff(message,logfile)
  err_log = File.open("#{$log_dir}#{logfile}", "a")
  err_log.puts "#{Time.now} - #{message}\n"
  err_log.close
end

def git_modified
  # git = Grit::Repo.new("../")
  git = IO.popen("git status")

  modified_file = File.open("#{$log_dir}#{$modified_log}", "w")
  modified_file.puts "These files were modified since the last commit:\n\n"
  # git.status.changed.each {|filename| modified_file.puts "#{filename[0]}\n"}
  git.each {|line| modified_file.puts line}
  modified_file.close
end

def strip_tags(data)
  data = Sanitize.clean(data, :remove_contents => ["script", "style"]) # strips all html tags and removes content between <script> and <style> tags
  return data
end

def format_tos(tos_data)
  begin
  tos_data = strip_tags(tos_data) # uses Sanitize to strip html
  # puts "worked"
  rescue Encoding::CompatibilityError
    # puts "rescued"
    tos_data.encode!("UTF-8", :undef => :replace)
    tos_data = strip_tags(tos_data)
  rescue ArgumentError
    # puts "Argument error"
    tos_data.encode!('ISO-8859-1', {:invalid => :replace, :undef => :replace})
    tos_data.encode!('UTF-8', {:invalid => :replace, :undef => :replace})
    tos_data = strip_tags(tos_data)
  end

  tos_data.gsub!(/\s{2,}/," ") # changes big gaps of space to a single space
  tos_data.gsub!(/\./,".\n") # adds new line char after all "."'s
  tos_data.gsub!(/\n\s/,"\n") # removes single spaces at the beginning of lines
  
  return tos_data
end

def parse_xml_files(rules_path, results_path)
  # files = []
  Dir.foreach(rules_path) do |filename| # loop for each xml file/rule
    next if filename == "." || filename == ".."
    
    begin
      filecontent = File.open("#{rules_path}#{filename}")
      ngxml = Nokogiri::XML(filecontent)
    rescue
      log_stuff("Script had trouble opening this file: #{rules_path}#{filename}",$error_log)
    ensure
      filecontent.close

    end
        
    new_path = "#{results_path}#{ngxml.xpath("//sitename[1]/@name").to_s}/"
    Dir.mkdir(new_path) unless File.exists?(new_path)
    
    docs = []
    ngxml.xpath("//sitename/docname").each do |doc|
      docs << doc.at_xpath("./@name")
    end
    
    docs.each do |name| # for every docname in sitename in file
      crawl_file_name = "#{new_path}#{name}.txt"
      crawl_file = File.open(crawl_file_name,"w") # new file or overwrite old file
      
      doc_url = ngxml.at_xpath("//docname[@name='#{name}']/url/@name")
      doc_xpath = ngxml.at_xpath("//docname[@name='#{name}']/url/@xpath") # Grabs xpath attribute from <url xpath="">
      
      begin
        ngdoc_url = Nokogiri::HTML(open(doc_url))
      rescue
        log_stuff("Problem opening URL(404?): #{doc_url}",$error_log)
        next
      end
      
      tos_data = ""
      if doc_xpath.nil?
        tos_data = ngdoc_url.at_xpath("//body").to_s
      else 
        tos_data = ngdoc_url.at_xpath(doc_xpath.to_s).to_s
      end
      
      tos_data = format_tos(tos_data)
      
      crawl_file.puts tos_data
      crawl_file.close
    end
        
  end
  
end

# code stuff



log_stuff("Beginning script!",$run_log)

parse_xml_files(rules_path,results_path)

#TODO mail git_modified

log_stuff("Script finished! Check #{$error_log} for rules to fix :)",$run_log)

git_modified