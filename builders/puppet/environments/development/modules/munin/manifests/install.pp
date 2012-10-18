# Class: munin::install
#
#
class munin::install {
    package { "munin-node":
        ensure => installed,
    }
}