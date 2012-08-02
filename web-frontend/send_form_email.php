<?php

$email_from = "java@zenn.net";     
$email_to = "asa@mac.com";
$email_subject = "suggested policy";
          
foreach($_POST as $key => $val) { 
	$email_message .= "$key: $val\n"; 
}

// create email headers
$headers = 'From: '.$email_from."\r\n".
'Reply-To: '.$email_from."\r\n";
@mail($email_to, $email_subject, $email_message, $headers);  
?>
  
Thank you for your suggested privacy policy.
 
<?php
?>