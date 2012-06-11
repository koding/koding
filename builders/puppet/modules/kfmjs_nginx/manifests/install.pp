# Class: kfmjs_nginx::install
#
#
class kfmjs_nginx::install {
    package { "nginx":
        ensure  => installed,
        require => Class['kfmjs_nginx::repo']
    }
}
