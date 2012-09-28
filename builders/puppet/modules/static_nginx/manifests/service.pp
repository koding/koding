# Class: static_nginx::service
#
#
class static_nginx::service {
    service { "nginx":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["static_nginx::config"],
    }
}
