# Class: kfmjs_nginx::service
#
#
class kfmjs_nginx::service {
    service { "nginx":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["kfmjs_nginx::config"],
    }
}
