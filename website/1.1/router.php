<?php

class Router {
  
  private $listener_key;
  
  function __construct($listener_key="ಠ_ಠ") {
    $this->tree = array();
    $this->listener_key = $listener_key;
  }

  public function add_route($route, $listener) {
    $edges = explode('/', $route);
    array_shift($edges);
    $node =& $this->tree;
    foreach ($edges as $edge) {
      if ($edge[0] == ':') {
        $node[':'] = array('name' => substr($edge, 1));
        $node =& $node[':'];
      }
      elseif (!isset($node[$edge])) {
        $node[$edge] = array();
        $node =& $node[$edge];
      }
      else {
        $node =& $node[$edge];
      }
    }
    if (!isset($node[$this->listener_key])) {
      $node[$this->listener_key] = array();
    }
    array_push($node[$this->listener_key], $listener);
  }
  
  public function handle_route($route) {
    $edges = explode('/', $route);
    array_shift($edges);
    $node =& $this->tree;
    $params = array();
    foreach ($edges as $edge) {
      if(isset($node[$edge])) {
        $node =& $node[$edge];
      }
      elseif (isset($node[':'])) {
        $param = $node[':'];
        $params[$param['name']] = $edge;
        $node =& $param;
      }
      else {
        return FALSE;
      }
    }
    $listeners = $node[$this->listener_key];
    foreach ($listeners as $listener) {
      $listener((object) $params);
    }
    return TRUE;
  }
}