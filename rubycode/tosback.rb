require 'open-uri'
require 'nokogiri'


path = '../tosback2/rules'

def get_xml_files(path)
  files = []
  Dir.foreach(path) do |f|
    next if f == "." || f == ".."
    files << f.strip
  end
  return files
end



# 
# 
# filepath1 = ARGV[0]
# filepath2 = ARGV[1]
# filepath3 = ARGV[2]
# 
# file1 = File.open(filepath1, "r")
# file2 = File.open(filepath2, "r")
# newfile = (File.exists?(filepath3) ? File.open(filepath3, "a") : File.new(filepath3, "w"))
# 
# file1.each {|line|
#  newfile.puts(line)
#  newfile.puts(file2.readline)
# }
# 
# file1.close
# file2.close
# newfile.close
# 
# #!/usr/bin/env ruby
# 
# #methods
# def file2array (filename)
#   contents = []
# 
#   file = File.open(filename, "r")
#   file.each { |line|
#     contents << line.strip
#   }
#   
#   file.close
#   return contents
# end
# 
# def inBoth (arr1, arr2)
#   return (arr1 & arr2)
# end
# 
# matchfile = ARGV[0]
# masterfile = ARGV[1]
# 
# masterarray = file2array (masterfile)
# matcharray = file2array (matchfile)
# 
# bothArray = inBoth(matcharray, masterarray)
# 
# bothArray.each {|diff|
#   puts diff
# }