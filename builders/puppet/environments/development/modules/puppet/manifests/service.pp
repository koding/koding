class puppet::service {
  service { "puppet":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
  }
}
