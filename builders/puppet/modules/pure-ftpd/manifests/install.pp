#
#
class pure-ftpd::install {
    package { ["pure-ftpd","fortune-mod"]:
        ensure  => installed,
        require => Class["yumrepos::epel"]
    }
}
