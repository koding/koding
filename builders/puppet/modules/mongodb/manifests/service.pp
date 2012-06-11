class mongodb::service {
    

  
  service { "mongod":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    #require => [Class["mongodb::config"],Class["dblvm::mount"]]
    require => Class["mongodb::config"]
  } 
}
