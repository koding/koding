# Class: nginx::service
#
#
class nginx_fm::service {
    service { "nginx":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["nginx_fm::config"],
    }
}
