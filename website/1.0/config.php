<?php

define("TIME_ZONE",    "America/New_York");
define('TRACE_LOG', '/home/cthorn/koding/website/1.0/.tmp/dev-api-trace.log');

date_default_timezone_set(TIME_ZONE);

$query = $_GET;
$query['data'] = json_decode($query['data'],true);


if ($query['env']=="vpn"){
  $dbName = "kodingen";
  $dbHost = "184.173.138.98";
  $dbPort = "27017";
  $dbUser = "kodingen_user";
  $dbPass = "Cvy3_exwb6JI";
}
elseif ($query['env'] == 'stage') {
  error_log('local db');
  $dbName = "koding_stage";
  $dbHost = "localhost";
  $dbPort = "38017";
  $dbUser = "koding_stage_user";
  $dbPass = "dkslkds84ddj";
}
elseif ($query['env'] == "mongohq-dev" || $_SERVER['HTTP_X_FORWARDED_HOST'] == 'dev-api.koding.com') {
  $dbName = "koding_copy";
  $dbHost = "alex.mongohq.com";
  $dbPort = "10065";
  $dbUser = "dev";
  $dbPass = "633939V3R6967W93A";
}
else {
  error_log('local db');
  $dbName = "beta_koding";
  $dbHost = "localhost";
  $dbPort = "27017";
  $dbUser = "PROD-koding";
  $dbPass = "34W4BXx595ib3J72k5Mh";
}

$headers = getallheaders();

if ($headers['X-Forwarded-Host'] == 'api.koding.com') {
  $env = 'beta';
  $pusher_key = 'a19c8bf6d2cad6c7a006';
  $pusher_secret = '51f7913fbb446767a9fb';
  $pusher_app_id = 18240;
}
else {
  $env = 'mongohq-dev';
  $pusher_key = 'a6f121a130a44c7f5325';
  $pusher_secret = '9a2f248630abaf977547';
  $pusher_app_id = 22120;
}

$connStr = "mongodb://{$dbUser}:{$dbPass}@{$dbHost}:{$dbPort}/{$dbName}";

try {
	if(!isset($mongo)) $mongo = new Mongo($connStr, array("persist" => $dbName));
    //echo 'connection established.';
} catch (Exception $e) {
	//commment in to see what the exception is
  //echo 'Caught exception: ',  $e->getMessage(), "\n";
  respondWith(array("error" => "DB connection can't be established.".$e->getMessage()));
}
