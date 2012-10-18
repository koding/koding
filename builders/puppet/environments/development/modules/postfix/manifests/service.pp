class postfix::service {
  service { "postfix":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["postfix::config"],
  } 
}