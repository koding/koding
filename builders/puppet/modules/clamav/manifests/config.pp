
#
class clamav::config {
    File {
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    
    file { "/etc/clamd.conf":
        ensure => present,
        source  => "puppet:///modules/clamav/etc/clamd.conf",
        require => Class["clamav::install"],
        notify  => Class["clamav::service"],
    }

}
