class ssh::config {
  file { "/etc/ssh/sshd_config":
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => 0600,
    source => "puppet:///modules/ssh/etc/ssh/sshd_config",
    require => Class["ssh::install"],
    notify => Class["ssh::service"],
  }
}