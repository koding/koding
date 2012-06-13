# Class: nginx::install
#
#
class nginx_fm::install {
    package { "nginx":
        ensure  => installed,
        require => Class['nginx_fm::repo']
    }
}
