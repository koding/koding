class clamav::service {
  service { "clamd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => [Class["clamav::config"],Class["clamav::initial_update"]]
  } 
}
