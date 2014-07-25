<?php

$sandBoxMode = 0;
$paymentPath = $sandBoxMode == 1 ? 'sandbox' : 'www';

error_reporting($sandBoxMode);

$ipnMailTo = "two7unsuited@gmail.com";
$from = "tester@example.com";
$ipnMailHeaders = "From:" . $from;

$backAction = "success";
if($backAction == "notify" || $backAction == "success"){
	$soo = '';
	while( list( $field, $value ) = each( $_POST )) {
		$soo .= "" . $field . " = " . $value . "\n";
	}

	$req = 'cmd=_notify-validate';
	foreach ($_POST as $key => $value) {
		$value = urlencode(stripslashes($value));
		$req .= "&$key=$value";
	}

	$header = "POST /cgi-bin/webscr HTTP/1.1\r\n";
	$header .= "Content-Type: application/x-www-form-urlencoded\r\n";
	$header .= "Host: www.paypal.com\r\n";
	$header .= "Connection: close\r\n";
	$header .= "Content-Length: " . strlen($req) . "\r\n\r\n";
	$fp = fsockopen('ssl://'.$paymentPath.'.paypal.com', 443, $errno, $errstr, 30);

	if(!$fp) {
		$subject = "IPN FSOCK Failed";
		$message = "Hello! \r\n\r\n".$soo;
		mail($ipnMailTo, $subject, $message, $ipnMailHeaders);
		exit;	
	}
    
   if($fp){
	fputs($fp, $header . $req);
	while(!feof($fp)) {
	   $res = fgets ($fp, 1024);
	   $res = trim($res); //NEW & IMPORTANT

	   $ppTxnType = $_POST['txn_type'];
	   if(strcmp($res, "VERIFIED") == 0) {


		$yourexistinguser = trim($_POST['option_selection1']);
		file_put_contents('/var/www/ipn2.txt', " Your user {$yourexistinguser} subscripted \n ", FILE_APPEND);
		exec("/var/www/changestaus.sh '{$yourexistinguser}'");

		$subject = "IPN Success Notify";
		$message = "Hello! - ".$soo;
		mail($ipnMailTo, $subject, $message, $ipnMailHeaders);  
	   }
	   if(strcmp($res, "INVALID") == 0) {
		$subject = "IPN Failure Notify";
		$message = " Hello! - ".$soo;
		mail($ipnMailTo, $subject, $message, $ipnMailHeaders);  
	   }
	}
	fclose($fp);
   } 
}





?>