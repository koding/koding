# Class: timezone
#
#
class timezone {
    package { "tzdata":
        ensure => installed
    }
    
    file { "/etc/localtime":
        owner => 'root',
        group => 'root',
        mode  => '0644',
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/US/Pacific",
    }
}