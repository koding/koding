# Class: nginx::install
#
#
class nginx_proxy::install {
    package { "nginx":
        ensure  => installed,
        require => Class['nginx_proxy::repo']
    }
}
