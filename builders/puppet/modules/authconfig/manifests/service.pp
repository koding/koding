class authconfig::service {
  service { "sssd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["authconfig::config"]
  }
}
