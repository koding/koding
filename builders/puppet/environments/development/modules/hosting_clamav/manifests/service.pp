class hosting_clamav::service {
  service { "clamd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["hosting_clamav::config"],
  } 
}
