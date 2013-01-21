# Class: stunell::install
#
#
class stunnel::install {
    package { "stunnel":
        ensure => installed,
        require => Class["yumrepos::epel"],
    }
}