class redis::service {
    

  
  service { "redis":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["redis::config"]
  } 
}
