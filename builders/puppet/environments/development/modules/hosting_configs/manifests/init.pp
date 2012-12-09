# Class: hosting_configs
#
#
class hosting_configs {
    
    File {
        owner => 'root',
        group => 'root',
        mode => '0644',
    }
    
    file { "/etc/security/limits.conf":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/security/limits.conf",
    }
    
    file { "/etc/login.defs":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/login.defs",
    }
    
    file { "/etc/sysctl.conf":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/sysctl.conf",
    }
    exec { "sysctl":
        command => "/sbin/sysctl -p",
        refreshonly => true,
        subscribe => File["/etc/sysctl.conf"],
    }
    file { "/etc/profile.d/java.sh":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/profile.d/java.sh",
        notify => Class["cloudlinux::cagefs_update"]
    }
   file { "/etc/profile.d/umask.sh":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/profile.d/umask.sh",
        notify => Class["cloudlinux::cagefs_update"]
    }
    file { "/etc/profile.d/path.sh":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/profile.d/path.sh",
        notify => Class["cloudlinux::cagefs_update"]
    }
   
   file { "/etc/yum.conf":
        ensure => file,
        source => "puppet:///modules/hosting_configs/etc/yum.conf",
    }

   file { "/Users":
        ensure => directory,
        owner => "root",
        group => "secure",
        mode => 0710,
        require => Group["secure"],
  }
    
    
}
