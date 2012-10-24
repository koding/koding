class mail_relay::postfix_service {
  service { "postfix":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["mail_relay::config"],
  }
  
}