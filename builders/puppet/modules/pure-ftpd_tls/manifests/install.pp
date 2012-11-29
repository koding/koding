#
#
class pure-ftpd_tls::install {
    package { ["pure-ftpd","fortune-mod"]:
        ensure  => installed,
        require => Class["yumrepos::epel"]
    }
}
