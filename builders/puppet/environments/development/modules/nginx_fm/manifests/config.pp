# Class: nginx::config
#
#
class nginx_fm::config {
    file { "/etc/nginx/nginx.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_fm/etc/nginx.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["nginx_fm::install"],
        notify  => Class["nginx_fm::service"],
    }
    
    file { "/etc/nginx/conf.d/fm.koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_fm/etc/conf.d/fm.koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_fm::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["nginx_fm::service"],
    }
    file { "/etc/nginx/ssl":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => '0700',
        require => Class["nginx_fm::install"],
    }

    file { "/etc/nginx/ssl/server.crt":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/nginx_fm/etc/ssl/server.crt",
        notify  => Class["nginx_fm::service"],
        require => File["/etc/nginx/ssl"],
    }

    file { "/etc/nginx/ssl/server.key":
        ensure => file,
        mode   => '0600',
        source => "puppet:///modules/nginx_fm/etc/ssl/server.key",
        notify  => Class["nginx_fm::service"],
        require => File["/etc/nginx/ssl"],
    }
}
