class munin::service {
  service { "munin-node":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["munin::config"],
  } 
}