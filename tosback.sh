#!/bin/bash
source /usr/local/rvm/environments/ruby-2.3.1@tb2
LANG=en_US.UTF-8

cd /root/tosback2/rubycode
bundle exec ruby main.rb 
git push
