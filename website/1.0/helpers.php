<?php

$env = isset($_REQUEST['env']) ? $_REQUEST['env'] : 'mongohq-dev';
$respond = isset($_REQUEST['callback']) ? 'jsonp_respond' : 'json_respond';

function trace () {
  error_log(implode(' ', array_map(function ($value) {
    return var_export($value, TRUE);
  }, func_get_args())));
}

function handle_vacated_channel ($type, $event, $ms) {
  $kite_controller = get_kite_controller();
  list(,$kite_id, $requester_id) = explode('-', $event->channel);
  $kite_uri = $kite_controller->get_kite_uri($kite_id, $requester_id);
  trace(implode(array('sending disconnect event', $kite_id, $requester_id), ' '));
  $query = array(
    'toDo' => '_disconnect',
    'secretChannelId' => $event->channel,
  ); 
  $uri = $kite_uri."?username={$requester_id}&data=".urlencode(json_encode($query));
  $result = @file_get_contents($uri);
  trace($uri, $result);
}

function get_session () {
  $db = get_mongo_db();
  if (!isset($_REQUEST['n'])) {
    return NULL;
  }
  $session = $db->jSessions->findOne(array(
    'tokens.token'  => $_COOKIE['clientId'],
    'nonces'        => $_REQUEST['n'],
  ));
  $db->jSessions->update(array(
    '_id' => $session['_id'],
  ), array(
    '$pull' => array(
      'nonces' => $_REQUEST['nonce']
    ),
  ));
  return $session;
}

function require_valid_session () {
  $session = get_session();
  $token = get_token($session);
  if (time() > $token['expires']->sec) {
    trace('expired token! ');
    access_denied('session has expired');
  }
  return $session;
}

function get_token ($session) {
  if (!isset($session['tokens'])) {
    trace('no session tokens! ');
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
  $out = is_string($ob) ? $ob : json_encode($ob);
  print $_REQUEST['callback'].'('.$out.')';
  die();
}

function json_respond ($ob) {
  header('Access-Control-Allow-Origin: https://beta.koding.com');
  header('Access-Control-Allow-Credentials: true');
  header('Access-Control-Allow-Methods: GET,POST,OPTIONS');
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
    'vpn'         => 'mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98',
    'beta'        => 'mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost',
    'mongohq-dev' => 'mongodb://dev:YzaCHWGkdL2r4f@staff.mongohq.com:10016',
  );
  return $hosts[$env];
}

function get_mongo_db_name () {
  global $env;
  $db_names = array(
    'vpn'         => 'kodingen',
    'beta'        => 'beta_koding',
    'mongohq-dev' => 'koding',
  );
  return $db_names[$env];
}

function get_mongo_db () {
  $db = get_mongo_db_name();
  $connection_string = get_mongo_host().'/'.$db;
  @$mongo = new Mongo($connection_string, array('persist' => 'api'));
  if(!isset($mongo)) {
    access_denied(2);
  }
  return $mongo->$db;
}

function get_kite_controller () {
  global $kite_controller;
  if (isset($kite_controller)) {
    return $kite_controller;
  }
  $kite_controller = new KiteController(dirname(dirname(dirname(__FILE__))).'/config/kite_config.json', get_mongo_db());
  return $kite_controller;
}
// 
// $kites = array( 
//   'beta' => array(
//     'sharedHosting' => 'http://cl2.beta.service.aws.koding.com:4566/',
//     'terminaljs'    => 'http://cl2.beta.service.aws.koding.com:4567/',
//     'databases'     => 'http://cl2.beta.service.aws.koding.com:4568/',
//   ),
//   'vpn' => array(
//     'sharedHosting' => 'http://cl3.beta.service.aws.koding.com:4566/',
//     'terminaljs'    => 'http://cl3.beta.service.aws.koding.com:4567/',
//     'databases'     => 'http://cl3.beta.service.aws.koding.com:4568/',
//   ),
// );

// function get_next_kite_uri ($kite_name) {
//   global $kites, $env;
//   return $kites[$env][$kite_name];
// }
// 
// function get_kite ($kite_name, $username) {
//   $db = get_mongo_db();
//   $connection = $db->jKiteConnections->findOne(array(
//     'kiteName' => $kite_name,
//     'username' => $username,
//   ), array('kiteUri' => 1));
//   if(!isset($connection)) {
//     $connection = array(
//       'kiteName' => $kite_name,
//       'username' => $username,
//       'kiteUri' => get_next_kite_uri($kite_name),
//     );
//     $mongo->$db->jKiteConnections->save($connection);
//   }
//   return $connection['kiteUri'];
// }
