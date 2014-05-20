#!/bin/bash
source /usr/local/rvm/environments/ruby-1.9.3-p547
LANG=en_US.UTF-8

cd /root/tosback2/rubycode
bundle exec ruby main.rb 
git push
