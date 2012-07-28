<?php

# example:
# http://localisoc.org/tosback2/git_file.php?i=6ac84d9be56d0ac9ac9b6e27d6e4b48dd9ca9559&f=crawls/www.facebook.com/Privacy-Policy/raw/www.facebook.com/full_data_use_policy.html
#
# TODO SECURITY: make sure that the parameters are in a valid and safe format
#
$output = shell_exec('/Library/WebServer/Documents/isoc/tosback2/git_file.sh ' . $_REQUEST["i"] . ' ' . $_REQUEST["f"]);
echo "$output";

?>