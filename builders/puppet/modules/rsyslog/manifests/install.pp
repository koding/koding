#
#
class rsyslog::install {
    
    package { "rsyslog":
        ensure => installed,
    }
}
