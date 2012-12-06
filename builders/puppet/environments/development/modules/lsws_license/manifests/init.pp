# Class: litespeed::serial
#
#
define lsws_license ($serial_no) {
    file { "serial":
        ensure => file,
        path => "/opt/lsws/serial.no",
        owner => "root",
        group => "root",
        mode => 0700,
        content => $serial_no,
        notify => Exec["register"],
        require => [Class["litespeed::deploy"],Class['litespeed::config']]
    }
    
    exec { "register":
        command => "/opt/lsws/bin/lshttpd -r",
        subscribe => File["serial"],
        refreshonly => true,
        logoutput => "on_failure",
        notify => Class["litespeed::service"]
    }
    
}
