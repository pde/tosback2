require 'nokogiri'
require 'open-uri'
require 'sanitize'

rules_path = "../rules_test/"
results_path = "../crawl/"

def format_tos(tos_data)
  begin
  tos_data = Sanitize.clean(tos_data, :remove_contents => ["script"])
  # puts "worked"
  rescue Encoding::CompatibilityError
    tos_data.encode!("UTF-8", undef: :replace)
    tos_data = Sanitize.clean(tos_data, :remove_contents => ["script"])
    # puts "rescued"
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
    
    filecontent = File.open("#{rules_path}#{filename}")
    ngxml = Nokogiri::XML(filecontent)
    filecontent.close
        
    new_path = "#{results_path}#{ngxml.xpath("//sitename[1]/@name").to_s}/"
    Dir.mkdir(new_path) unless File.exists?(new_path)
    
    docs = []
    ngxml.xpath("//sitename/docname").each do |doc|
      docs << doc.at_xpath("./@name")
    end
    
    docs.each do |name| # for every docname in sitename
      crawl_file_name = "#{new_path}#{name}.txt"
      crawl_file = File.open(crawl_file_name,"w")
      
      doc_url = ngxml.at_xpath("//docname[@name='#{name}']/url/@name")
      doc_xpath = ngxml.at_xpath("//docname[@name='#{name}']/url/@xpath")
      ngdoc_url = Nokogiri::HTML(open(doc_url))
      
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

