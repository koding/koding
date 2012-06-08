class hosting_ssh::config {
  file { "/etc/ssh/sshd_config":
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => 0600,
    source => "puppet:///modules/hosting_ssh/etc/ssh/sshd_config",
    require => Class["hosting_ssh::install"],
    notify => Class["hosting_ssh::service"],
  }
}
