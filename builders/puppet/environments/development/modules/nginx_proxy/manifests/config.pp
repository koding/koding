# Class: nginx::config
#
#
class nginx_proxy::config {
    file { "/etc/nginx/nginx.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/nginx.conf",
        owner   => 'root',
        group   => 'root',
        require => Class["nginx_proxy::install"],
        notify  => Class["nginx_proxy::service"],
    }
    
    file { "/etc/nginx/conf.d/beta.koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/conf.d/beta.koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["nginx_proxy::service"],
    }
     
    file { "/etc/nginx/conf.d/koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/conf.d/koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["nginx_proxy::service"],
    }

    file { "/opt/Apps":
        ensure => directory,
        mode => 755,
        owner => 'root',
        group => 'root',
    }

    file { "/etc/nginx/conf.d/app.koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/conf.d/app.koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf'],File["/opt/Apps"]],
        notify  => Class["nginx_proxy::service"],
    }


    file { "/etc/nginx/conf.d/default.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/conf.d/default.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["nginx_proxy::service"],
    }

}
