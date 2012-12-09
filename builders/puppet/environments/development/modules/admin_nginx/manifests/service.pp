# Class: nginx::service
#
#
class admin_nginx::service {
    service { "nginx":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["admin_nginx::config"],
    }
}
