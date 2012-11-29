class hosting_ssh::service {
  service { "sshd":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["hosting_ssh::config"],
   }
}
