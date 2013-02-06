# Class: cloudlinux::cagefs_configs
#
#
class cloudlinux::cagefs_configs {
    File {
        ensure => 'file',
        mode  => '0644',
        owner => 'root',
        group => 'root',
        notify => Class["cloudlinux::cagefs_update"],
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
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/vcs.cfg",
        require => [Class['hosting_packages::vcs'],Exec['cagefs_init']]
    }


    file { "/etc/cagefs/conf.d/nodejs.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/nodejs.cfg",
        require => [Class['nodejs_rpm::install'],Exec['cagefs_init']]
    }
    

    file { "/etc/cagefs/conf.d/python.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/python.cfg",
        require => [Class['hosting_packages::python'],Exec['cagefs_init']]
    }
    file { "/etc/cagefs/conf.d/php.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/php.cfg",
        require => [Class['hosting_packages::php'],Exec['cagefs_init']]
    }


    file { "/etc/cagefs/conf.d/ruby.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/ruby.cfg",
        require => [Class['hosting_packages::ruby'],Exec['cagefs_init']]
    }
     
    #file { "/etc/cagefs/conf.d/mail.cfg":
    #    ensure => file,
    #    source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mail.cfg",
    #    notify => Class["cloudlinux::cagefs_update"],
    #    require => [Class['postfix'],Exec['cagefs_init']]
    #}
    
    
    file { "/etc/cagefs/conf.d/fun.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/fun.cfg",
        require => [Class['hosting_packages::fun'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/mysql-client.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mysql-client.cfg",
        require => [Class['hosting_packages::mysql'],Exec['cagefs_init']]
    }

   file { "/etc/cagefs/conf.d/mongo-client.cfg":
        source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/mongo-client.cfg",
        require => [Class['hosting_packages::mongo'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/openssl.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/openssl.cfg",
           require => Exec['cagefs_init']
     }
    
    file { "/etc/cagefs/conf.d/coreutils.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/coreutils.cfg",
           require => Exec['cagefs_init']
    }

    file { "/etc/cagefs/conf.d/openssh-clients.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/openssh-clients.cfg",
           require => Exec['cagefs_init']
    }

    file { "/etc/cagefs/conf.d/java.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/java.cfg",
           require => [Class['hosting_packages::java'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/ftp.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/ftp.cfg",
           require => [Class['hosting_packages::ftp'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/editors.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/editors.cfg",
           require => [Class['hosting_packages::editors'],Exec['cagefs_init']]
    }


   file { "/etc/cagefs/conf.d/devel.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/devel.cfg",
           require => Exec['cagefs_init'],
    }
    
    file { "/etc/cagefs/conf.d/tools.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/tools.cfg",
           require => [Class['hosting_packages::tools'],Exec['cagefs_init']]
    }
    file { "/etc/cagefs/conf.d/erlang.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/erlang.cfg",
           require => [Class['hosting_packages::erlang'],Exec['cagefs_init']]
    }

    file { "/etc/cagefs/conf.d/procps.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/procps.cfg",
           require => [Class['hosting_packages::tools'],Exec['cagefs_init']]
    }
   file { "/etc/cagefs/conf.d/golang.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/golang.cfg",
           require => [Class['hosting_packages::compilers'],Exec['cagefs_init']]
    }
    file { "/etc/cagefs/conf.d/haskel.cfg":
           source => "puppet:///modules/cloudlinux/etc/cagefs/conf.d/haskel.cfg",
           require => [Class['hosting_packages::haskel'],Exec['cagefs_init']]
    }
   
   
    file { "/etc/cagefs/cagefs.mp":
           source => "puppet:///modules/cloudlinux/etc/cagefs/cagefs.mp",
           notify => Class["cloudlinux::cagefs_remount_all"],
           require => [Exec['cagefs_init'],Class[authconfig::service],Class[cloudlinux::shared_dir]] # remount cagefs only when sssd installed and running
    }

}
