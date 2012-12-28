
#
class hosting_clamav::config {
    File {
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    
    file { "/etc/clamd.conf":
        ensure => present,
        source  => "puppet:///modules/hosting_clamav/etc/clamd.conf",
        require => Class["hosting_clamav::install"],
        notify  => Class["hosting_clamav::service"],
    }

}
