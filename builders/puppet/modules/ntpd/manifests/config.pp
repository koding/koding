
#
class ntpd::config {
    File {
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    
    file { "/etc/ntp.conf":
        ensure => present,
        source  => "puppet:///modules/ntpd/etc/ntp.conf",
        require => Class["ntpd::install"],
        notify  => Class["ntpd::service"],
    }

}
