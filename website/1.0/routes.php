<?php

require_once 'router.php';

$env = isset($_GET['env']) ? $_GET['env'] : 'beta';
$respond = isset($_REQUEST['callback']) ? 'jsonp_respond' : 'json_respond';

function handle_vacated_channel($type, $event, $ms) {
  global $kites;
  list(,$kite_id, $requester_id) = explode('-', $event->channel);
  error_log(implode(array('sending disconnect event', $kite_id, $requester_id), ' '));
  $query = array(
    'toDo' => '_disconnect',
    'secretChannelId' => $event->channel,
  );
  
  $uri = $kites[$kite_id]."?username={$requester_id}&data=".urlencode(json_encode($query));
  @file_get_contents($uri);
}

function get_session () {
  $db = get_mongo_db_name();
  $mongo = get_mongo();
  $session = $mongo->$db->jSessions->findOne(array(
    'tokens.token' => $_COOKIE['clientId'],
  ), array(
    'username'  => 1,
    'tokens'    => 1,
  ));
  $token = get_token($session);
  if(time() > $token['expires']->sec) {
    error_log('expired token! '.var_export($token, TRUE));
    access_denied('session has expired');
  }
  return $session;
}

function get_token ($session) {
  if (!isset($session['tokens'])) {
    error_log('no session tokens! '. var_export($session, TRUE));
  }
  else {
    foreach ($session['tokens'] as $token) {
      if ($token['requester'] == 'api.koding.com') {
        break;
      }
    }
  }
  return $token;
}

function jsonp_respond ($ob) {
  header('Content-type: text/javascript');
  $out = is_array($ob) ? json_encode($ob) : $ob;
  print $_REQUEST['callback'].'('.$out.')';
  die();
}

function json_respond ($ob) {
  header('Access-Control-Allow-Origin: *');
  header('Content-type: text/javascript');
  $out = is_array($ob) ? json_encode($ob) : $ob;
  print $out;
  die();
}

function access_denied ($msg=NULL) {
  global $respond;
  header('HTTP/1.0 403 Forbidden');
  $response = array('error' => 403);
  if (isset($msg)) {
    $response['message'] = $msg;
  }
  $respond($response);
}

function okay () {
  global $respond;
  $respond(array('result' => 200));
}

function get_mongo_host () {
  global $env;
  $hosts = array(
    'vpn'   => 'mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98',
    'beta'  => 'mongodb://beta_koding_user:lkalkslakslaksla1230000@db0.beta.system.aws.koding.com',
  );
  return $hosts[$env];
}

function get_mongo_db_name () {
  global $env;
  $db_names = array(
    'vpn'   => 'kodingen',
    'beta'  => 'beta_koding',
  );
  return $db_names[$env];
}

function get_mongo () {
  $db = get_mongo_db_name();
  $connection_string = get_mongo_host().'/'.$db;
  @$mongo = new Mongo($connection_string, array('persist' => 'api'));
  if(!isset($mongo)) {
    access_denied(2);
  }
  return $mongo;
}

$kites = array( 
  'beta' => array(
    'sharedHosting' => 'http://cl2.beta.service.aws.koding.com:4566/',
    'terminaljs'    => 'http://cl2.beta.service.aws.koding.com:4567/',
    'databases'     => 'http://cl2.beta.service.aws.koding.com:4568/',
  ),
  'vpn' => array(
    'sharedHosting' => 'http://cl3.beta.service.aws.koding.com:4566/',
    'terminaljs'    => 'http://cl3.beta.service.aws.koding.com:4567/',
    'databases'     => 'http://cl3.beta.service.aws.koding.com:4568/',
  ),
);

function get_next_kite_uri($kite_name) {
  global $kites, $env;
  error_log('ENV '.$env);
  return $kites[$env][$kite_name];
}

function get_kite ($kite_name, $username) {
  $db = get_mongo_db_name();
  $mongo = get_mongo();
  $connection = $mongo->$db->jKiteConnections->findOne(array(
    'kiteName' => $kite_name,
    'username' => $username,
  ), array('kiteUri' => 1));
  if(!isset($connection)) {
    $connection = array(
      'kiteName' => $kite_name,
      'username' => $username,
      'kiteUri' => get_next_kite_uri($kite_name),
    );
    $mongo->$db->jKiteConnections->save($connection);
  }
  return $connection['kiteUri'];
}

$router = new Router;

$router->add_route('/kite/:kite_name', function ($params) {
  global $respond;
  //header('Access-Control-Allow-Origin: *');
  header('Content-type: text/javascript');
  $session = get_session();
  $uri = get_kite($params->kite_name, $session['username']);
  if(!isset($uri)) {
    header('HTTP/1.0 404 Not Found');
    $respond(array('error' => 404));
  }
  else {
    $args = $_REQUEST;
    if (isset($session)) {
      $args['username'] = $session['username'];
      $res = @file_get_contents($uri.'?'.http_build_query($args));
      if ($res) {
        $respond($res);
      }
      else {
        header('HTTP/1.0 503 Service Unavailable');
        $respond(array('error' => 503, 'uri' => $uri));
      }      
    }
  }
});

$router->add_route('/event', function () {
  @$message = json_decode(file_get_contents('php://input'));
  // error_log(json_encode($message));
  if(isset($message)) {
    foreach ($message->events as $event) {
      switch($event->name) {
      case 'channel_vacated' :
        $matches = array();
        if(preg_match('/^private-(\w+)-/', $event->channel, $matches)) {
          list(, $channel_type) = $matches;
          handle_vacated_channel($channel_type, $event, $message->time_ms);
        }
        break;
      }
    }
  }
  okay();
});

$router->add_route('/login', function () {
  $nonce = $_GET['n'];
  if (!isset($nonce)) {
    access_denied(1);
  }
  $db = get_mongo_db_name();
  $mongo = get_mongo();
  $session = $mongo->$db->jSessions->findOne(array('nonce' => $nonce));
  if (!isset($session)) {
    access_denied(3);
  }
  $mongo->$db->jSessions->update(array(
    'nonce' => $nonce,
  ), array(
    '$unset' => array(
      'nonce' => 1,
    ),
  ));
  $token = get_token($session);
  if (!isset($token)) {
    access_denied(4);
  }
  setcookie('clientId', $token['token'], $token['expires']->sec);
  okay();
});

$router->add_route('/logout', function () {
  setcookie('clientId', '', time()-3600);
  okay();
});

// $router->add_route('/devrim', function () {
//   //print file_get_contents('http://www.google.com');
//   okay();
// });
