<?php
require_once 'helpers.php';
require_once 'kitecluster.php';
require_once 'kite.php';

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

class KiteController {
  private $kites;
  
  function __construct ($config_path, $db) {
    $this->config_path = $config_path;
    $config_json = @file_get_contents($config_path);
    if (empty($config_json)) {
      error_log("Invalid configuration: $config_path");
      return;
    }
    else {
      $this->config = $this->initialize_config($config_json);
      $this->db = $db;
    }
  }
  
  public function initialize_config ($config_json) {
    $config = json_decode($config_json);
    $db = get_mongo_db();
    foreach ($config->kites as $kite_name => $kite) {
      $this->clusters[$kite_name] = array();
      foreach ($kite->clusters as $cluster) {
        $active_cluster = $db->jKiteClusters->findOne(array(
          'kiteName' => $kite_name,
        ));
        if (!isset($active_cluster)) {
          $active_cluster = array(
            'kiteName'  => $kite_name,
            'kites'     => array(),
          );
          $db->jKiteClusters->save($active_cluster);
        }
        array_push(
          $this->clusters[$kite_name],
          new KiteCluster($cluster, $active_cluster['kites'])
        );
      }
    }
  }
  
  public function add_kite ($kite_name, $uri) {
    $parsed_uri = parse_url($uri);
    $result = array('addedTo' => array());
    $clusters = $this->clusters[$kite_name];
    if (!isset($clusters)) {
      error_log("No cluster found for kites named $kite_name");
      return FALSE;
    }
    foreach ($clusters as $index=>$cluster) {
      if ($cluster->trustPolicy->test('byHostname', $parsed_uri['host'])
       && $cluster->add_kite($kite_name, $uri)) {
        if ($kite_name != 'pinger') {
          $pinger = $this->get_kite('pinger', 'kc');
          $pinger->startPinging(array(
            'kiteName'  => $kite_name,
            'uri'       => $uri,
            'interval'  => 5000,
          ));
        }
        array_push($result['addedTo'], $index);
      }
    }
    if (count($result['addedTo'])) {      
      error_log("kite was added to $kite_name clusters: ".implode(', ', $result['addedTo']));
      return TRUE;
    }
    return FALSE;
  }
  
  public function remove_kite ($kite_name, $uri) {
    
  }

  private function _get_next_kite_uri ($kite_name) {
    $clusters = $this->clusters[$kite_name];
    $kite = $clusters[0]->kites[0];
    if (isset($kite)) {
      error_log('found no kites');
      return FALSE;
    }
    else {
      return $kite;
    }
    // global $kites, $env;
    // error_log('bitch '.var_export($kites, TRUE).' '.$env);
    // return $kites[$env][$kite_name];
  }

  public function get_kite_uri ($kite_name, $username) {
    $db = get_mongo_db();
    $connection = $db->jKiteConnections->findOne(array(
      'kiteName' => $kite_name,
      'username' => $username,
    ), array('kiteUri' => 1));
    if(!isset($connection)) {
      $connection = array(
        'kiteName' => $kite_name,
        'username' => $username,
        'kiteUri' => $this->_get_next_kite_uri($kite_name),
      );
      $db->jKiteConnections->save($connection);
    }
    return $connection['kiteUri'];
  }
  
  public function get_kite ($kite_name, $username) {
    return new Kite($kite_name, $this->get_kite_uri($kite_name, $username));
  }
  
}