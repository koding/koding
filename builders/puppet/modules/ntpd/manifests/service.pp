class ntpd::service {
  service { "ntpd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["ntpd::config"],
  } 
}