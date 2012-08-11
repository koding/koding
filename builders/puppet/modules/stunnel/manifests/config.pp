# Class: stunnel::config
#
#
class stunnel::config {
    File {
        owner   => 'root',
        group   => 'root',
        require => Class["stunnel::install"] 
    }
    
    file { "/etc/stunnel/stunnel.conf":
        ensure => file,
        source => "puppet:///modules/stunnel/etc/stunnel/stunnel.conf",
        mode   => '0644',
        notify  => Class["monit::service"]
    }
    
    file { "/etc/stunnel/ssl":
        ensure => directory,
        mode   => '0700',
    }
    
    file { "/var/run/stunnel/":
        ensure => directory,
        mode   => '0700',
        owner  => 'nobody',
        group  => 'nobody',
    }
    
    file { "/etc/stunnel/ssl/server.crt":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/stunnel/etc/stunnel/ssl/server.crt",
        notify  => Class["monit::service"]
    }
    
    file { "/etc/stunnel/ssl/server.key":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/stunnel/etc/stunnel/ssl/server.key",
        notify  => Class["monit::service"]
    }
    
    file { "/etc/stunnel/init.sh":
        ensure => file,
        source => "puppet:///modules/stunnel/etc/stunnel/init.sh",
        mode   => '0744',
        notify  => Class["monit::service"]
    }
    
}