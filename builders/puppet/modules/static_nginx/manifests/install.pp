# Class: static_nginx::install
#
#
class static_nginx::install {
    package { "nginx":
        ensure  => installed,
        require => Class['static_nginx::repo']
    }
}
