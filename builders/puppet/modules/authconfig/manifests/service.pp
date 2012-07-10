class authconfig::service {
  service { "sssd":
    ensure => stopped,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["authconfig::config"]
  }
}
