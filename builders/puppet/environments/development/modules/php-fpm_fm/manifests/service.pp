class php-fpm_fm::service {
  service { "php-fpm":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
  }
}
