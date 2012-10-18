class monit::config {

    
    file { "scripts_dir":
        ensure => directory,
        path => "/etc/monit.d/scripts",
        require => Class["monit::install"],
    }
    
    file { "/etc/monit.conf":
        ensure => present,
        owner => "root",
        group => "root",
        mode => 0700,
        #require => [Class["monit::install"],Class["gluster_client"],Class["nodejs_rpm::install"]], 
        #require => [Class["monit::install"],Class["nodejs_rpm::install"]], 
        require => [Class["monit::install"]], 
        notify  => Class["monit::service"],
        source => "puppet:///modules/monit/etc/monit.conf",
        before  => Exec["restart_monit"]
    }
    
    exec { "restart_monit":
        command => "/sbin/service monit restart",
        alias => "restart monit",
        subscribe => File["/etc/monit.conf"],
        refreshonly => true,
        logoutput => "on_failure",
    }

}
