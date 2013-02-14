# Class: static_nginx::config
#
#
class static_nginx::config {
    file { "/etc/nginx/nginx.conf":
        ensure  => file,
        source  => "puppet:///modules/static_nginx/etc/nginx.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["static_nginx::install"],
        notify  => Class["static_nginx::service"],
    }
    
    file { "/etc/nginx/conf.d/api.koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/static_nginx/etc/conf.d/api.koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["static_nginx::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["static_nginx::service"],
    }
    
    file { "/etc/nginx/conf.d/dev-api.koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/static_nginx/etc/conf.d/dev-api.koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["static_nginx::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["static_nginx::service"],
    }

    file { "/etc/nginx/ssl":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => '0700',
        require => Class["static_nginx::install"],
    }

    file { "/etc/nginx/ssl/server.crt":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/static_nginx/etc/ssl/server.crt",
        notify  => Class["static_nginx::service"],
        require => File["/etc/nginx/ssl"],
    }

    file { "/etc/nginx/ssl/server.key":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/static_nginx/etc/ssl/server.key",
        notify  => Class["static_nginx::service"],
        require => File["/etc/nginx/ssl"],
    }
####
    file { "/etc/nginx/ssl/server_new.crt":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/static_nginx/etc/ssl/server_new.crt",
        notify  => Class["static_nginx::service"],
        require => File["/etc/nginx/ssl"],
    }

    file { "/etc/nginx/ssl/server_new.key":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/static_nginx/etc/ssl/server_new.key",
        notify  => Class["static_nginx::service"],
        require => File["/etc/nginx/ssl"],
    }
   
}
