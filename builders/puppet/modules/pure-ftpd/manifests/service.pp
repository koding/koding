# Class: nginx::service
#
#
class pure-ftpd::service {
    service { "pure-ftpd":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["pure-ftpd::config"],
    }

}
