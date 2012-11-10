<?php
require_once 'config.php';
require_once 'routes.php';
require_once 'helpers.php';

// $params = explode('/', preg_replace('/^\/\d+\.\d+\//', '', $_SERVER['REDIRECT_URL']));
// // $route = array_shift($params);
//
// switch($route) {
// case 'invitation' :
//  #header(200);
//  print json_encode($params);
//  die();
// }


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
    header('Content-type: text/javascript');
    echo  $query['callback']."(" . json_encode($res) . ")";
}

function getFeed($collection,$limit,$sort,$skip){
    global $mongo,$dbName,$query;

    $type     = $query["data"]["type"];
    $isPublic = $query["data"]["isPublic"];
    $originId = isset($query["data"]["originId"]) ? new MongoId(
      $query["data"]["originId"]
    ) : array(
      '$ne' => -1,
    );

    $limit = $limit == "" ? 20    : $limit;
    $skip  = $skip  == "" ? 0     : $skip;
    $type  = $type        ? $type : array( '$nin' => array('CFolloweeBucketActivity'));

    $activityQuery = array(
      "snapshot"  => array( '$exists'  => true ),
      "type"      => $type,
      "originId"  => $originId,
      "isPublic"  => $isPublic,
    );

    if (!isset($query['t'])) {
      $activityQuery['isLowQuality'] = array( '$ne' => true );
    }

    switch ($collection){
        case 'cActivities':
            $cursor = $mongo->$dbName->$collection->find($activityQuery,array('snapshot' => true));
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
