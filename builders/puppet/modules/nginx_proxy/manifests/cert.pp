#
#
class nginx_proxy::cert {
    file { "/etc/nginx/ssl":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => 0700,
        require => Class["nginx_proxy::install"],
        notify  => Class["nginx_proxy::service"],
    }
    
    file { "/etc/nginx/ssl/server.crt":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/ssl/server.crt",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf'],File['/etc/nginx/ssl']],
        notify  => Class["nginx_proxy::service"],
    }

    file { "/etc/nginx/ssl/server.key":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/ssl/server.key",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf'],File['/etc/nginx/ssl']],
        notify  => Class["nginx_proxy::service"],
    }
    file { "/etc/nginx/ssl/server_new.crt":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/ssl/server_new.crt",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf'],File['/etc/nginx/ssl']],
        notify  => Class["nginx_proxy::service"],
    }

    file { "/etc/nginx/ssl/server_new.key":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/ssl/server_new.key",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf'],File['/etc/nginx/ssl']],
        notify  => Class["nginx_proxy::service"],
    }

}
