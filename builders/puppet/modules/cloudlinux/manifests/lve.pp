# Class: cloudlinux::lve
#
#
class cloudlinux::lve {
    package { "lve-utils":
        ensure => installed,
    }
    
    file { "/etc/container/ve.cfg":
        ensure => file,
        owner => 'root',
        group => 'root',
        mode => '0644',
        #source => "puppet:///modules/cloudlinux/etc/container/ve.cfg",
        content => template("cloudlinux/ve.cfg.erb"),
        notify => Exec['lve_reload']
    }
    
    exec { "lve_reload":
        command => "/etc/init.d/lvectl reload && /usr/sbin/lvectl apply all",
        refreshonly => true,
    }
}
