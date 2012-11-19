<?php 

require_once 'routes.php';

// $params = explode('/', preg_replace('/^\/\d+\.\d+\//', '', $_SERVER['REDIRECT_URL']));
// // $route = array_shift($params);
// 
// switch($route) {
// case 'invitation' :
//  #header(200);
//  print json_encode($params);
//  die();
// }

define("TIME_ZONE",    "America/New_York");
date_default_timezone_set(TIME_ZONE);

$query = $_GET;
$query['data'] = json_decode($query['data'],true);

if ($query['env']=="dev"){
  $dbName = "kodingen";
  $dbHost = "184.173.138.98";
  $dbPort = "27017";
  $dbUser = "kodingen_user";
  $dbPass = "Cvy3_exwb6JI";
}
else {
  $dbName = "beta_koding";
  $dbHost = "localhost";
  $dbPort = "27017";
  $dbUser = "PROD-koding";
  $dbPass = "34W4BXx595ib3J72k5Mh";
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


$route = preg_replace('/^\/'.array_pop(explode('/', dirname(__FILE__))).'/', '', $_GET['q']);
if (!$route || !$router->handle_route($route)) {
  switch ($query['data']['collection']){

      case 'activities':
          respondWith(getFeed('cActivities',$query['data']['limit'],$query['data']['sort'],$query['data']['skip']));
          break;
      case 'topics':
          respondWith(getFeed('jTags',$query['data']['limit'],$query['data']['sort'],$query['data']['skip']));
          break;
      default:
          respondWith(array("error"=>"not a  valid collection",));
  } 
}

function respondWith($res){
    global $query;
    echo  $query['callback']."(" . json_encode($res) . ")";
}

function getFeed($collection,$limit,$sort,$skip){
    global $mongo,$dbName,$query;

    $type  =  $query["data"]["type_filter"];
  
    $limit = $limit == "" ? 20    : $limit;
    $skip  = $skip  == "" ? 0     : $skip;
    $type  = $type        ? $type : Array( '$nin' => Array('CFolloweeBucketActivity'));
  
    switch ($collection){
        case 'cActivities':
            $cursor = $mongo->$dbName->$collection->find(
              Array(
                "snapshot"  => Array( '$exists'  => true ),
                "type"      => $type
              ),
              Array('snapshot' => true));

            break;
        case 'jTags':
            $cursor = $mongo->$dbName->$collection->find();
            break;
        default:
            break;
    }            
    $cursor->sort($sort);
    $cursor->limit($limit);
    $cursor->skip($skip);
    $r = array();
    foreach ($cursor as $doc) array_push($r,$doc);

    return $r;
}
