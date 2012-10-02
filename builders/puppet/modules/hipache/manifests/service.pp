class hipache::service {
  
  service { "hipache":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["hipache::config"]
  } 
}
