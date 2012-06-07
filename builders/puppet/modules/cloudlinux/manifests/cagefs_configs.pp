# Class: cloudlinux::cagefs_configs
#
#
class cloudlinux::cagefs_configs {
    File {
        mode  => '0644',
        owner => 'root',
        group => 'root',
    }
        
    exec { "cagefs_init":
        command => "/usr/sbin/cagefsctl --init",
        onlyif => '/usr/bin/test ! -d  /usr/share/cagefs-skeleton',
        timeout => 0,
        notify => Exec['enable_cagefs'],
    }
    exec { "enable_cagefs":
        command => "/usr/sbin/cagefsctl --enable-all",
        timeout => 0,
        refreshonly => true,
    }
    
    #file { "/etc/cagefs/conf.d/lsphp.cfg":
    #    ensure => file,
    #    source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/lsphp.cfg",
    #    notify => Exec['/usr/sbin/cagefsctl'],
    #    #require => [Class["litespeed::deploy"],Exec['cagefs_init']]
    #    require => Exec['cagefs_init'],
    #}

    file { "/etc/cagefs/conf.d/vcs.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/vcs.cfg",
        notify => Exec['/usr/sbin/cagefsctl'],
        require => [Class['hosting_packages::vcs'],Exec['cagefs_init']]
    }


    file { "/etc/cagefs/conf.d/nodejs.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/nodejs.cfg",
        notify => Class["cloudlinux::cagefs_update"],
        require => [Class['nodejs_rpm::install'],Exec['cagefs_init']]
    }
    

    file { "/etc/cagefs/conf.d/python.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/python.cfg",
        notify => Class["cloudlinux::cagefs_update"],
        require => [Class['hosting_packages::python'],Exec['cagefs_init']]
    }
    
    #file { "/etc/cagefs/conf.d/mail.cfg":
    #    ensure => file,
    #    source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mail.cfg",
    #    notify => Class["cloudlinux::cagefs_update"],
    #    require => [Class['postfix'],Exec['cagefs_init']]
    #}
    
    
    file { "/etc/cagefs/conf.d/fun.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/fun.cfg",
        notify => Class["cloudlinux::cagefs_update"],
        require => [Class['hosting_packages::fun'],Exec['cagefs_init']]
    }
    file { "/etc/cagefs/conf.d/mysql-client.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mysql-client.cfg",
        notify => Class["cloudlinux::cagefs_update"],
        require => [Class['hosting_packages::mysql'],Exec['cagefs_init']]
    }
   file { "/etc/cagefs/conf.d/mongo-client.cfg":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mongo-client.cfg",
        notify => Class["cloudlinux::cagefs_update"],
        require => [Class['hosting_packages::mongo'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/openssl.cfg":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/openssl.cfg",
           notify => Class["cloudlinux::cagefs_update"],
           require => Exec['cagefs_init']
     }
    
    file { "/etc/cagefs/conf.d/coreutils.cfg":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/coreutils.cfg",
           notify => Class["cloudlinux::cagefs_update"],
           require => Exec['cagefs_init']
    }
     file { "/etc/cagefs/conf.d/java.cfg":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/java.cfg",
           notify => Class["cloudlinux::cagefs_update"],
           require => [Class['hosting_packages::java'],Exec['cagefs_init']]
    }
      file { "/etc/cagefs/conf.d/ftp.cfg":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/ftp.cfg",
           notify => Class["cloudlinux::cagefs_update"],
           require => [Class['hosting_packages::ftp'],Exec['cagefs_init']]
    }
    file { "/etc/cagefs/conf.d/editors.cfg":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/editors.cfg",
           notify => Class["cloudlinux::cagefs_update"],
           require => [Class['hosting_packages::editors'],Exec['cagefs_init']]
    }
   
   
     file { "/etc/cagefs/cagefs.mp":
           ensure => file,
           source => "puppet:///modules/cloudlinux/etc/cagefs/cagefs.mp",
           notify => Class["cloudlinux::cagefs_remount_all"],
           require => [Exec['cagefs_init'],Class[authconfig::service]] # remount cagefs only when sssd installed and running
    }

}
