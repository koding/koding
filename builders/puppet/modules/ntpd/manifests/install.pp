
#
class ntpd::install {
    package { 'ntp':
        ensure => present,
    }
}