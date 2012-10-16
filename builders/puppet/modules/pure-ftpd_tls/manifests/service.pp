# Class: nginx::service
#
#
class pure-ftpd_tls::service {
    service { "pure-ftpd":
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => Class["pure-ftpd::config"],
    }

}
