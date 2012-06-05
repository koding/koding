<?php

class KiteLoadBalancer {
  public static function create($loadBalancing) {
    switch($loadBalancing->strategy) {
    case 'round robin' : return new KiteRoundRobinLoadBalancer($loadBalancing);
    }
  }
}

class KiteRoundRobinLoadBalancer extends KiteLoadBalancer {
  function __construct ($loadBalancing) {
    $this->loadBalancing = $loadBalancing;
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
  function __construct ($cluster, $kites=array()) {
    $this->name = $cluster->name;
    $this->kites = $kites;
    $this->interface = $cluster->interface;
    $this->loadBalancer = KiteLoadBalancer::create($cluster->loadBalancing);
    $this->trustPolicy = new KiteTrustPolicy($cluster->trustPolicy);
  }
  
  public function add_kite ($kite_name, $uri) {
    if (in_array($uri, $this->kites)) {
      error_log("Kite at $uri already registered.  Refusing to add again.");
      return FALSE;
    }
    else {
      $db = get_mongo_db();
      $db->jKiteClusters->update(array(
        'kiteName' => $kite_name,
      ), array(
        '$addToSet' => array(
          'kites' => $uri,
        ),
      ));
      return TRUE;
    }
  }
}