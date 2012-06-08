class cluebringer::service {
  service { "cbpolicyd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => [Class["cluebringer::config"]]
  }
  
}