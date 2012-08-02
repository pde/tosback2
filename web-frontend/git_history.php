<?php

# example:
# http://localisoc.org/tosback2/git_history.php?p=crawls/www.facebook.com/Privacy-Policy/raw/www.facebook.com/full_data_use_policy.html
#
# TODO SECURITY: make sure that the parameter is in a valid and safe format
#
$output = shell_exec('/Library/WebServer/Documents/isoc/tosback2/git_history.sh ' . $_REQUEST["p"]);
echo "var policyHistory = { list:$output };";

?>
