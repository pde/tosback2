require 'nokogiri'
require 'open-uri'
require 'sanitize'
require 'mechanize' # will probably need to use this instead to handle sites that require session info
require 'mail'
require 'active_record'
# require 'pry' #debug

Dir["lib/*.rb"].each {|file| require "./#{file}" }
# assumes we only need sql if running the full script in production
ActiveRecord::Base.establish_connection(TOSBackSecrets.get_mysql_hash) if ARGV.length == 0

$rules_path = "../rules/" # Directories should include trailing slash
$results_path = "../crawl/"
$reviewed_crawl_path = "../crawl_reviewed/"
$log_dir = "../logs/"
$error_log = "errors.log"
$run_log = "run.log"
$modified_log = "modified.log"
$empty_log = "empty.log"
$dev_log = "dev.log"
$notifier = TOSBackNotifier.instance

if ARGV.length == 0
  TOSBackApp.log_stuff("Beginning script!",$run_log)
  
  tba = TOSBackApp.new($rules_path)
  
  tba.run_app

elsif ARGV[0] == "-empty"
  
  TOSBackApp.find_empty_crawls($results_path,512)

elsif ARGV[0] == "-dev"
  tba = TOSBackApp.new($rules_path)
  
  tba.run_app_dev
else
  filecontent = File.open(ARGV[0])
  ngxml = Nokogiri::XML(filecontent)
  filecontent.close

  site = ngxml.xpath("//sitename[1]/@name").to_s
  
  docs = []
  
  ngxml.xpath("//sitename/docname").each do |doc|
    docs << TOSBackDoc.new({site: site, name: doc.at_xpath("./@name").to_s, url: doc.at_xpath("./url/@name").to_s, xpath: doc.at_xpath("./url/@xpath").to_s, reviewed: doc.at_xpath("./url/@reviewed").to_s})
  end
  
  docs.each do |doc|
    doc.scrape
    doc.write
  end
end
