class mongodb-slave::service {
    

  
  service { "mongod":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["mongodb-slave::config"]
  } 
}
