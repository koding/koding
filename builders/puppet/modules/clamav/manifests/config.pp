
#
class clamav::config {
    File {
        owner => "root",
        group => "root",
        mode => 0644,
    }
    
    file { "/var/lib/clamav":
        ensure => directory,
        owner => "clamav",
        group => "clamav",
    }

    file { "/etc/clamd.conf":
        ensure => present,
        source  => "puppet:///modules/clamav/etc/clamd.conf",
        require => Class["clamav::install"],
        notify  => Class["clamav::service"],
    }

    file { "/etc/freshclam.conf":
        ensure => present,
        source  => "puppet:///modules/clamav/etc/freshclam.conf",
        require => Class["clamav::install"],
        notify  => Class["clamav::service"],
    }

}
