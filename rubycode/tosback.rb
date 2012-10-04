require 'nokogiri'
require 'open-uri'
require 'sanitize'

rules_path = "../rules/"
results_path = "../crawl/"
$log_dir = "../logs/"

def log_errors(error)
  err_log = File.open("#{$log_dir}errors.log", "a")
  err_log.puts "#{Time.now} - #{error}\n"
  err_log.close
end

def strip_tags(data)
  data = Sanitize.clean(data, :remove_contents => ["script", "style"])
  return data
end

def format_tos(tos_data)
  begin
  tos_data = strip_tags(tos_data)
  # puts "worked"
  rescue Encoding::CompatibilityError
    # puts "rescued"
    tos_data.encode!("UTF-8", undef: => :replace)
    tos_data = strip_tags(tos_data)
  rescue ArgumentError
    # puts "Argument error"
    tos_data.encode!('ISO-8859-1', :invalid => :replace, :undef => :replace)
    tos_data.encode!('UTF-8', :invalid => :replace, :undef => :replace)    
    tos_data = strip_tags(tos_data)
  end

  tos_data.gsub!(/\s{2,}/," ")
  tos_data.gsub!(/\./,".\n")
  tos_data.gsub!(/\n\s/,"\n")
  
  return tos_data
end

def parse_xml_files(rules_path, results_path)
  # files = []
  Dir.foreach(rules_path) do |filename|
    next if filename == "." || filename == ".."
    
    begin
      filecontent = File.open("#{rules_path}#{filename}")
      ngxml = Nokogiri::XML(filecontent)
    rescue
      log_errors("Script had trouble opening this file: #{rules_path}#{filename}")
    ensure
      filecontent.close

    end
        
    new_path = "#{results_path}#{ngxml.xpath("//sitename[1]/@name").to_s}/"
    Dir.mkdir(new_path) unless File.exists?(new_path)
    
    docs = []
    ngxml.xpath("//sitename/docname").each do |doc|
      docs << doc.at_xpath("./@name")
    end
    
    docs.each do |name| # for every docname in sitename
      crawl_file_name = "#{new_path}#{name}.txt"
      crawl_file = File.open(crawl_file_name,"w") # new file or overwrite old file
      
      doc_url = ngxml.at_xpath("//docname[@name='#{name}']/url/@name")
      doc_xpath = ngxml.at_xpath("//docname[@name='#{name}']/url/@xpath")
      
      begin
        ngdoc_url = Nokogiri::HTML(open(doc_url))
      rescue
        log_errors("Problem opening URL: #{doc_url}")
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

parse_xml_files(rules_path,results_path)

