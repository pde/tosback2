#!/bin/bash  
cd /Library/WebServer/Documents/isoc/tosback2/tosback2
#/usr/bin/git show $1:$2
#/usr/bin/git show 6ac84d9be56d0ac9ac9b6e27d6e4b48dd9ca9559:crawls/www.facebook.com/Privacy-Policy/raw/www.facebook.com/full_data_use_policy.html
/usr/bin/git show $1:$2 | python /Library/WebServer/Documents/isoc/tosback2/prettify.py
#cd /Library/WebServer/Documents/isoc/tosback2/
