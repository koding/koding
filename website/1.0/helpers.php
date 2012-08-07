<?php

require_once 'config.php';

$respond = 'json_respond';

function trace () {
  error_log(implode(' ', array_map(function ($value) {
    return var_export($value, TRUE);
  }, func_get_args())));
}

trace($headers);

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

function print_cors_headers () {
  $headers = getallheaders();
  list($origin) = explode(' ', $headers['Origin']);
  if (in_array($origin, array('https://koding.com', 'https://beta.koding.com'))) {
    header('Access-Control-Allow-Origin: '.$origin);
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Methods: GET,POST,OPTIONS');
  }
}

function print_json_headers () {
  header('Content-type: text/javascript');
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
  trace('jsonp_respond should never be used!');
}

function json_respond ($ob) {
  print_cors_headers();
  print_json_headers();
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

function get_mongo_db_name () {
  global $env;
  $db_names = array(
    'vpn'         => 'kodingen',
    'beta'        => 'beta_koding',
    'mongohq-dev' => 'koding_copy',
  );
  return $db_names[$env];
}

function get_mongo_db () {
  global $connStr;
  $db = get_mongo_db_name();
  @$mongo = new Mongo($connStr, array('persist' => 'api'));
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
