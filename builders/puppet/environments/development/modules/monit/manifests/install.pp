# Class: postfix:install
#
#
class monit::install {
    package { "monit":
        ensure => present,
        require => Class["yumrepos::epel"],
    }
}