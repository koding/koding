# Class: nginx::install
#
#
class admin_nginx::install {
    package { "nginx":
        ensure  => installed,
        require => Class['admin_nginx::repo']
    }
}
