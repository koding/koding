# Class: nginx::service
#
#
class nginx_proxy::service {
    service { "nginx":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["nginx_proxy::config"],
    }
}
