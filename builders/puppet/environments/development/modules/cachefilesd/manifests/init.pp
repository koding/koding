class cachefilesd {

    package { "cachefilesd":
        ensure => installed,
    }
    file { "/etc/cachefilesd.conf":
        source => "puppet:///modules/cachefilesd/cachefilesd.conf",
        owner => root,
        group => root,
        require => Package["cachefilesd"],
    }    
    service { "cachefilesd":
        ensure => running,
        enable => true,
        require => [Package["cachefilesd"],File['/etc/cachefilesd.conf']],
    }


}

