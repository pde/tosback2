require 'nokogiri'
require 'open-uri'

rules_path = "../rules_test/"
results_path = "../crawl/"

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
      doc_xpath = ngxml.at_xpath("//docname[@name='#{name}']/url/@xpath").content
      ngdoc_url = Nokogiri::HTML(open(doc_url))
      if doc_xpath.nil?
        crawl_file.puts ngdoc_url.at_xpath("//body").content.strip.squeeze!("\t")                
      else
        crawl_file.puts ngdoc_url.at_xpath(doc_xpath).content.strip.squeeze!("\t")
      end
      
      # crawl_file.puts "#{name} / " + ngxml.at_xpath("//docname[@name='#{name}']/url/@name")
      crawl_file.close
    end
        
  end
  
end

parse_xml_files(rules_path,results_path)

