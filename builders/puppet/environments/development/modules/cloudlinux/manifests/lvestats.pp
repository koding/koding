# Class: cloudlinux::lvestats
#
#
class cloudlinux::lvestats {
    package { "lve-stats":
        ensure => installed,
    }

    file { "/etc/sysconfig/lvestats":
        ensure  => file,
        owner => 'root',
        group => 'root',
        mode => '0644',
        content => template("cloudlinux/lvestats.erb"),
        require => Package["lve-stats"],
        notify => Service['lvestats'],
    }

    service { "lvestats":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => [Package['lve-stats'],File['/etc/sysconfig/lvestats'],Class["hosting_packages::python"]]
    }
 
}
