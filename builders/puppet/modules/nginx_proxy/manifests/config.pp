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
    
    file { "/etc/nginx/conf.d/koding.com.conf":
        ensure  => file,
        source  => "puppet:///modules/nginx_proxy/etc/conf.d/koding.com.conf",
        owner   => 'root',
        group   => 'root',
        require => [Class["nginx_proxy::install"],File['/etc/nginx/nginx.conf']],
        notify  => Class["nginx_proxy::service"],
    }
    
    file { "/etc/nginx/conf.d/hosting_upstream_map":
        ensure  => file,
        replace=>"no", # Only add a file if it’s absent
        require => [Class["nginx_proxy::install"],File['/etc/nginx/conf.d/koding.com.conf']],
    }
}
