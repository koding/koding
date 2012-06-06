<?php

require_once 'helpers.php';

class KiteLoadBalancer {
  // abstract public function get_next_kite_uri(&$cluster);
  public static function create($loadBalancing) {
    switch($loadBalancing->strategy) {
    // case 'round robin'        :
    default :
      return new KiteRoundRobinLoadBalancer($loadBalancing);
    }
  }
}

class KiteRoundRobinLoadBalancer extends KiteLoadBalancer {
  function __construct ($loadBalancing) {
    $this->loadBalancing = $loadBalancing;
  }
  
  public function get_next_kite_uri (&$cluster) {
    # get the next kite index
    $i = count($cluster->kites) % ($cluster->connectionCount + 1);
    return $cluster['kites'][$i];
  }
}

class KiteTrustPolicy {
  function __construct ($trustPolicy) {
    $this->rules = array();
    foreach ($trustPolicy as $strategy => $rule) {
      switch ($strategy) {
      case 'byHostname':
        $this->rules['byHostname'] = function ($hostname) use ($rule) {
          $rule = preg_replace('/\./', '\.', $rule);
          $hostname_preg = '/'.preg_replace('/\*/', '(?:[a-z0-9-]+)', strtolower($rule)).'/';
          return preg_match($hostname_preg, strtolower($hostname));
        };
        break;
      }
    }
  }

  public function test($rule, $value) {
    $test = $this->rules[$rule];
    return @$test($value);
  }
}

class KiteCluster {
  function __construct ($kite_name, $cluster) {
    $this->kite_name = $kite_name;
    $this->name = $cluster->name;
    $this->interface = $cluster->interface;
    $this->loadBalancer = KiteLoadBalancer::create($cluster->loadBalancing);
    $this->trustPolicy = new KiteTrustPolicy($cluster->trustPolicy);
    $this->initialize();
  }
  
  private function initialize() {
    $db = get_mongo_db();
    $active_cluster = $db->jKiteClusters->findOne(array(
      'kiteName' => $this->kite_name,
    ));
    if (!isset($active_cluster)) {
      error_log($this->kite_name.' not saved');
      $active_cluster = array(
        'kiteName'  => $this->kite_name,
        'kites'     => array(),
        'connectionCount' => 0,
      );
      $db->jKiteClusters->save($active_cluster);
    }
  }
  
  public function get_kites() {
    $record = $this->get_record();
    return $record['kites'];
  }
  
  private function get_record() {
    $db = get_mongo_db();
    return $db->jKiteClusters->findOne(array(
      'kiteName' => $this->kite_name,
    ));
  }
  
  public function get_next_kite_uri () {
    return $this->loadBalancer->get_next_kite_uri($this->get_record());
  }
  
  public function add_connection () {
    $db = get_mongo_db();
  }
  
  public function add_kite ($uri) {
    if (in_array($uri, $this->get_kites())) {
      error_log("Kite at $uri already registered.  Refusing to add again.");
      return FALSE;
    }
    else {
      $db = get_mongo_db();
      $db->jKiteClusters->update(array(
        'kiteName' => $this->kite_name,
      ), array(
        '$addToSet' => array(
          'kites' => $uri,
        ),
      ));
      return TRUE;
    }
  }
}