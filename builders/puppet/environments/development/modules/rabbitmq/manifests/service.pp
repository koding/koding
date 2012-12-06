class rabbitmq::service {
  service { "rabbitmq-server":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
  }
}
