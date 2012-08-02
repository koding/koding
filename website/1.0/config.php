<?php

define("TIME_ZONE",    "America/New_York");
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
elseif ($query['env'] == "mongohq-dev" || $_SERVER['HTTP_X_FORWARDED_HOST'] == 'dev-api.koding.com') {
  $dbName = "koding_copy";
  $dbHost = "alex.mongohq.com";
  $dbPort = "10065";
  $dbUser = "dev";
  $dbPass = "633939V3R6967W93A";
}
else {
  $dbName = "beta_koding";
  $dbHost = "localhost";
  $dbPort = "27017";
  $dbUser = "beta_koding_user";
  $dbPass = "lkalkslakslaksla1230000";
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


function get_mongo_host () {
  global $env;
  $hosts = array(
    'vpn'         => 'mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98',
    'beta'        => 'mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost',
    'mongohq-dev' => 'mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy',
  );
  return $hosts[$env];
}
